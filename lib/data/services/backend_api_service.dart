import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/config/server_config.dart';
import '../models/disease_result.dart';
import 'disease_history_hive_service.dart';

/// Exception thrown when user reaches the daily limitation of 2 crop disease uploads.
class DailyLimitExceededException implements Exception {
  DailyLimitExceededException({
    required this.message,
    required this.messageBn,
    this.limit = 2,
    this.used = 2,
    this.remaining = 0,
  });

  final String message;
  final String messageBn;
  final int limit;
  final int used;
  final int remaining;

  @override
  String toString() => message;
}

/// Information about user's daily quota.
class DailyLimitInfo {
  DailyLimitInfo({
    required this.limit,
    required this.used,
    required this.remaining,
    this.canUpload = true,
  });

  final int limit;
  final int used;
  final int remaining;
  final bool canUpload;
}

/// Service that delegates database requests, crop disease AI detection,
/// and AI chat to the dedicated Smart Agri cPanel backend server.
class BackendApiService {
  BackendApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> _buildHeaders(String userId, {String? deviceId}) {
    return {
      'Accept': 'application/json',
      'X-SmartAgri-Secret': ServerConfig.appSecret,
      'Authorization': 'Bearer ${ServerConfig.appSecret}',
      'X-User-ID': userId,
      if (deviceId != null && deviceId.isNotEmpty) 'X-Device-ID': deviceId,
    };
  }

  /// Checks the user's remaining daily crop disease uploads on the backend server.
  Future<DailyLimitInfo> getDailyLimitStatus(String userId) async {
    try {
      if (!ServerConfig.isConfigured) {
        throw StateError('No backend server configured');
      }
      final uri = Uri.parse('${ServerConfig.baseUrl}/disease/limit-status?user_id=${Uri.encodeComponent(userId)}');
      final response = await _client.get(
        uri,
        headers: _buildHeaders(userId),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final limit = (data['limit'] ?? 2) as int;
        final used = (data['used'] ?? 0) as int;
        final remaining = (data['remaining'] ?? (limit - used)) as int;

        // Cache in Hive for offline instant access
        await DiseaseHistoryHiveService.instance.cacheDailyLimit(
          used: used,
          remaining: remaining,
          date: (data['date'] ?? '').toString(),
        );

        return DailyLimitInfo(
          limit: limit,
          used: used,
          remaining: remaining,
          canUpload: remaining > 0,
        );
      }
    } catch (e) {
      debugPrint('[BackendApiService] Failed to fetch live limit: $e');
    }

    // Fallback to local Hive cache
    final cached = DiseaseHistoryHiveService.instance.getCachedDailyLimit();
    if (cached != null) {
      final used = (cached['used'] ?? 0) as int;
      final remaining = (cached['remaining'] ?? (ServerConfig.maxDailyDiseaseScans - used)) as int;
      return DailyLimitInfo(
        limit: ServerConfig.maxDailyDiseaseScans,
        used: used,
        remaining: remaining,
        canUpload: remaining > 0,
      );
    }

    return DailyLimitInfo(
      limit: ServerConfig.maxDailyDiseaseScans,
      used: 0,
      remaining: ServerConfig.maxDailyDiseaseScans,
      canUpload: true,
    );
  }

  /// Sends a crop image to the dedicated backend server for disease diagnosis.
  /// Enforces daily limit (max 2 images/day) and returns sequential bilingual steps.
  Future<DiseaseResult> detectDisease({
    required Uint8List bytes,
    required String filename,
    required String userId,
    String? deviceId,
  }) async {
    if (!ServerConfig.isConfigured) {
      throw Exception(
        'AI is not set up yet. Add GEMINI_API_KEY (or SERVER_BASE_URL) '
        'to assets/env/app.env and run the app again.',
      );
    }
    final uri = Uri.parse('${ServerConfig.baseUrl}/disease/detect');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_buildHeaders(userId, deviceId: deviceId));
      request.fields['user_id'] = userId;
      if (deviceId != null) request.fields['device_id'] = deviceId;

      final mimeType = _resolveMime(filename);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: filename.isNotEmpty ? filename : 'crop_scan.jpg',
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await _client.send(request).timeout(ServerConfig.timeout);
      final responseBody = await streamedResponse.stream.bytesToString();
      final statusCode = streamedResponse.statusCode;

      if (statusCode == 429) {
        // Daily Limit Exceeded
        Map<String, dynamic> errorJson = {};
        try {
          errorJson = jsonDecode(responseBody);
        } catch (_) {}

        final msgEn = errorJson['message'] ?? 'Daily limit reached. You can only analyze up to 2 crop images per day.';
        final msgBn = errorJson['message_bn'] ?? 'দৈনিক সীমা অতিক্রম হয়েছে। আপনি প্রতিদিন সর্বোচ্চ ২টি ফসলের ছবি পরীক্ষা করতে পারেন। অনুগ্রহ করে আগামীকাল আবার চেষ্টা করুন।';

        // Update local Hive limit cache
        await DiseaseHistoryHiveService.instance.cacheDailyLimit(
          used: 2,
          remaining: 0,
          date: DateTime.now().toIso8601String().split('T')[0],
        );

        throw DailyLimitExceededException(
          message: msgEn.toString(),
          messageBn: msgBn.toString(),
          limit: (errorJson['limit'] ?? 2) as int,
          used: (errorJson['used'] ?? 2) as int,
          remaining: 0,
        );
      }

      if (statusCode == 200) {
        final decoded = jsonDecode(responseBody);
        if (decoded['success'] == true && decoded['data'] != null) {
          final data = decoded['data'] as Map<String, dynamic>;
          
          // Encode thumbnail for offline Hive access (keep small)
          final base64Img = base64Encode(bytes.length > 300000 ? bytes.sublist(0, 300000) : bytes);
          final result = DiseaseResult.fromServerJson(data, imageBase64: base64Img);

          // Update limit info if returned
          if (decoded['limit_info'] != null) {
            final lim = decoded['limit_info'];
            await DiseaseHistoryHiveService.instance.cacheDailyLimit(
              used: lim['used'] ?? 1,
              remaining: lim['remaining'] ?? 1,
              date: DateTime.now().toIso8601String().split('T')[0],
            );
          }

          // Save to Hive local database for instant 0ms offline access
          await DiseaseHistoryHiveService.instance.saveScan(result);

          return result;
        } else {
          final msg = decoded['message_bn'] ?? decoded['message'] ?? 'সার্ভার থেকে সঠিক তথ্য পাওয়া যায়নি।';
          throw Exception(msg);
        }
      }

      // Other HTTP errors
      Map<String, dynamic> err = {};
      try {
        err = jsonDecode(responseBody);
      } catch (_) {}
      final msg = err['message_bn'] ?? err['message'] ?? 'সার্ভার ত্রুটি: কোড $statusCode';
      throw Exception(msg);
    } catch (e) {
      if (e is DailyLimitExceededException) rethrow;
      debugPrint('[BackendApiService] Error calling /disease/detect: $e');
      rethrow;
    }
  }

  /// Sends a message to the AI chatbot through the backend server.
  Future<String> sendChatMessage({
    required String userMessage,
    required List<Map<String, String>> history,
    required String userId,
  }) async {
    final uri = Uri.parse('${ServerConfig.baseUrl}/chat');

    try {
      final response = await _client.post(
        uri,
        headers: {
          ..._buildHeaders(userId),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'message': userMessage,
          'history': history,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['reply'] != null) {
          return decoded['reply'].toString();
        }
      }
    } catch (e) {
      debugPrint('[BackendApiService] Chat API failed: $e');
    }

    // Fallback friendly message
    return 'আসসালামু আলাইকুম কৃষক ভাই! সার্ভারে কিছুটা সাময়িক ট্রাফিক রয়েছে। '
        'ফসলের পরিচর্যার জন্য স্থানীয় কৃষি কর্মকর্তার পরামর্শ নিন অথবা কিছুক্ষণ পর আবার চেষ্টা করুন।';
  }

  String _resolveMime(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

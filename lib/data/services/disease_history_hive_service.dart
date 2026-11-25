import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/disease_result.dart';

/// Dedicated Local Hive Database Service for Crop Disease Scan History and Daily Quota.
/// Provides instant 0ms offline retrieval and fast local caching.
class DiseaseHistoryHiveService {
  DiseaseHistoryHiveService._();
  static final DiseaseHistoryHiveService instance = DiseaseHistoryHiveService._();

  static const String _historyBoxName = 'disease_history_box';
  static const String _metaBoxName = 'disease_meta_box';

  Box? _historyBox;
  Box? _metaBox;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized && _historyBox?.isOpen == true) return;
    try {
      _historyBox = await Hive.openBox(_historyBoxName);
      _metaBox = await Hive.openBox(_metaBoxName);
      _initialized = true;
      debugPrint('[DiseaseHistoryHiveService] Hive boxes initialized successfully.');
    } catch (e) {
      debugPrint('[DiseaseHistoryHiveService] Error initializing Hive: $e');
    }
  }

  /// Persists a new disease scan to the local Hive box.
  Future<void> saveScan(DiseaseResult result) async {
    if (!_initialized || _historyBox == null) return;
    try {
      final key = result.id.isNotEmpty ? result.id : DateTime.now().millisecondsSinceEpoch.toString();
      await _historyBox!.put(key, jsonEncode(result.toJson()));
      debugPrint('[DiseaseHistoryHiveService] Saved scan $key to Hive.');
    } catch (e) {
      debugPrint('[DiseaseHistoryHiveService] Error saving scan: $e');
    }
  }

  /// Retrieves all cached disease scan reports from local Hive box,
  /// ordered newest to oldest.
  List<DiseaseResult> getScans() {
    if (!_initialized || _historyBox == null) return [];
    try {
      final list = <DiseaseResult>[];
      for (final key in _historyBox!.keys) {
        final raw = _historyBox!.get(key);
        if (raw is String) {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            list.add(DiseaseResult.fromServerJson(decoded));
          }
        }
      }
      // Sort newest first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('[DiseaseHistoryHiveService] Error reading scans: $e');
      return [];
    }
  }

  /// Deletes a specific scan from local Hive storage.
  Future<void> deleteScan(String id) async {
    if (!_initialized || _historyBox == null) return;
    try {
      await _historyBox!.delete(id);
    } catch (e) {
      debugPrint('[DiseaseHistoryHiveService] Error deleting scan: $e');
    }
  }

  /// Caches the daily limit state locally (so remaining scans count is instant offline).
  Future<void> cacheDailyLimit({
    required int used,
    required int remaining,
    required String date,
  }) async {
    if (!_initialized || _metaBox == null) return;
    try {
      await _metaBox!.put('daily_limit', {
        'used': used,
        'remaining': remaining,
        'date': date,
        'cached_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[DiseaseHistoryHiveService] Error caching limit: $e');
    }
  }

  /// Reads cached daily limit from local Hive box.
  Map<String, dynamic>? getCachedDailyLimit() {
    if (!_initialized || _metaBox == null) return null;
    try {
      final raw = _metaBox!.get('daily_limit');
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
    } catch (e) {
      debugPrint('[DiseaseHistoryHiveService] Error reading cached limit: $e');
    }
    return null;
  }

  /// Clears all local history.
  Future<void> clearAll() async {
    if (!_initialized || _historyBox == null) return;
    await _historyBox!.clear();
  }
}

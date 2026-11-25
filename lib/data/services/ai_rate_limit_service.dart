import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exception thrown when user exceeds the 20 requests/day Gemini quota.
class GeminiRateLimitException implements Exception {
  const GeminiRateLimitException([
    this.message =
        'Daily AI request limit (20 requests/day) reached. Please try again tomorrow.\n(দৈনিক এআই সীমা ২০টি অনুরোধ শেষ হয়ে গেছে। আগামীকাল আবার চেষ্টা করুন।)',
  ]);

  final String message;

  @override
  String toString() => message;
}

/// Service that enforces the 20 requests/day rate limit for Gemini AI features.
class AiRateLimitService {
  AiRateLimitService._();
  static final AiRateLimitService instance = AiRateLimitService._();

  static const int maxDailyRequests = 20;
  static const String _prefPrefix = 'gemini_daily_requests_';

  String _todayKey() {
    final now = DateTime.now();
    return DateFormat('yyyy_MM_dd').format(now);
  }

  /// Returns total requests used today
  Future<int> getTodayRequestCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefPrefix${_todayKey()}';
      return prefs.getInt(key) ?? 0;
    } catch (e) {
      debugPrint('Error getting AI rate limit count: $e');
      return 0;
    }
  }

  /// Returns remaining requests for today (0 to 20)
  Future<int> getRemainingRequests() async {
    final used = await getTodayRequestCount();
    final remaining = maxDailyRequests - used;
    return remaining < 0 ? 0 : remaining;
  }

  /// Checks if user has remaining quota
  Future<bool> canMakeRequest() async {
    final used = await getTodayRequestCount();
    return used < maxDailyRequests;
  }

  /// Consumes 1 request from today's quota.
  /// Throws [GeminiRateLimitException] if daily limit is reached.
  Future<void> checkAndConsumeQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefPrefix${_todayKey()}';
    final current = prefs.getInt(key) ?? 0;

    if (current >= maxDailyRequests) {
      throw const GeminiRateLimitException();
    }

    await prefs.setInt(key, current + 1);
  }

  /// Formats the remaining time until midnight reset in English and Bangla
  String getResetTimeString({bool isBn = true}) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (isBn) {
      return '$hours ঘণ্টা $minutes মিনিট পর নতুন কোটা রিসেট হবে';
    } else {
      return 'Quota resets in ${hours}h ${minutes}m';
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that prevents brute-force attacks on email/password login.
/// Allows a maximum of 5 failed attempts, after which the account/device
/// is locked out for 1 hour.
class AuthRateLimitService {
  AuthRateLimitService._();
  static final AuthRateLimitService instance = AuthRateLimitService._();

  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(hours: 1);

  static const String _failedAttemptsKey = 'auth_failed_login_attempts';
  static const String _lockoutUntilKey = 'auth_lockout_until_timestamp';

  /// Returns whether login attempts are currently locked out.
  Future<bool> isLockedOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockoutUntilMs = prefs.getInt(_lockoutUntilKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (lockoutUntilMs > nowMs) {
        return true;
      }

      // Lockout expired, clean up if needed
      if (lockoutUntilMs > 0 && lockoutUntilMs <= nowMs) {
        await resetAttempts();
      }
      return false;
    } catch (e) {
      debugPrint('Error checking login lockout: $e');
      return false;
    }
  }

  /// Returns remaining minutes for the current lockout (or 0 if not locked)
  Future<int> getRemainingLockoutMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockoutUntilMs = prefs.getInt(_lockoutUntilKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (lockoutUntilMs <= nowMs) return 0;

      final diffMs = lockoutUntilMs - nowMs;
      final minutes = (diffMs / 60000).ceil();
      return minutes > 0 ? minutes : 1;
    } catch (e) {
      return 0;
    }
  }

  /// Returns current consecutive failed attempts count
  Future<int> getFailedAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_failedAttemptsKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Records a failed login attempt.
  /// If attempts reach 5, activates a 1-hour lockout.
  Future<int> recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getInt(_failedAttemptsKey) ?? 0) + 1;
    await prefs.setInt(_failedAttemptsKey, current);

    if (current >= maxFailedAttempts) {
      final lockoutUntil =
          DateTime.now().add(lockoutDuration).millisecondsSinceEpoch;
      await prefs.setInt(_lockoutUntilKey, lockoutUntil);
    }

    return current;
  }

  /// Resets failed attempts to 0 on successful login
  Future<void> resetAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_failedAttemptsKey);
      await prefs.remove(_lockoutUntilKey);
    } catch (e) {
      debugPrint('Error resetting login attempts: $e');
    }
  }

  /// Returns formatted error message for locked state
  String getLockoutErrorMessage({required int minutes, bool isBn = true}) {
    if (isBn) {
      return 'অতিরিক্ত ৫ বার ভুল পাসওয়ার্ড দেওয়ার কারণে অ্যাকাউন্টটি সাময়িকভাবে লক করা হয়েছে। অনুগ্রহ করে $minutes মিনিট পর পুনরায় চেষ্টা করুন।';
    } else {
      return 'Account temporarily locked due to 5 failed login attempts. Please wait $minutes minutes before trying again.';
    }
  }

  /// Returns warning message when attempts are nearing limit
  String getAttemptsWarningMessage({required int remaining, bool isBn = true}) {
    if (isBn) {
      return 'ভুল ইমেইল বা পাসওয়ার্ড। আর $remaining বার ভুল দিলে অ্যাকাউন্ট ১ ঘণ্টার জন্য লক হবে।';
    } else {
      return 'Incorrect email or password. $remaining attempts remaining before 1-hour lockout.';
    }
  }
}

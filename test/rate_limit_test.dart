import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_agri_assistant/data/services/ai_rate_limit_service.dart';
import 'package:ai_agri_assistant/data/services/auth_rate_limit_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AiRateLimitService Tests', () {
    test('Initial state allows requests with full quota (20)', () async {
      final service = AiRateLimitService.instance;
      final allowed = await service.canMakeRequest();
      expect(allowed, isTrue);

      final count = await service.getTodayRequestCount();
      expect(count, 0);

      final remaining = await service.getRemainingRequests();
      expect(remaining, 20);
    });

    test('Consumes quota up to daily limit (20) and then throws', () async {
      final service = AiRateLimitService.instance;
      for (int i = 0; i < 20; i++) {
        await service.checkAndConsumeQuota();
      }

      final remaining = await service.getRemainingRequests();
      expect(remaining, 0);

      final canMake = await service.canMakeRequest();
      expect(canMake, isFalse);

      expect(
        () async => await service.checkAndConsumeQuota(),
        throwsA(isA<GeminiRateLimitException>()),
      );
    });
  });

  group('AuthRateLimitService Tests', () {
    test('Lockout triggered after 5 failed login attempts', () async {
      final service = AuthRateLimitService.instance;
      expect(await service.isLockedOut(), isFalse);

      for (int i = 1; i <= 4; i++) {
        final count = await service.recordFailedAttempt();
        expect(count, i);
        expect(await service.isLockedOut(), isFalse);
      }

      // 5th attempt locks out
      final count = await service.recordFailedAttempt();
      expect(count, 5);
      expect(await service.isLockedOut(), isTrue);

      final remainingMinutes = await service.getRemainingLockoutMinutes();
      expect(remainingMinutes, inInclusiveRange(59, 60));

      // Reset works
      await service.resetAttempts();
      expect(await service.isLockedOut(), isFalse);
      expect(await service.getFailedAttempts(), 0);
    });
  });
}

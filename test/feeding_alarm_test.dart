import 'package:flutter_test/flutter_test.dart';
import 'package:ai_agri_assistant/data/services/feeding_alarm_service.dart';

void main() {
  group('FeedingAlarmService Schedule Tests', () {
    test('Contains valid fish feeding schedules for BST', () {
      final fishSchedules = FeedingAlarmService.feedingSchedules
          .where((s) => s.type == FeedingTargetType.fish)
          .toList();

      expect(fishSchedules.length, greaterThanOrEqualTo(2));

      // Morning fish feeding (08:00 AM)
      final morning = fishSchedules.firstWhere((s) => s.id == 101);
      expect(morning.hour, 8);
      expect(morning.minute, 0);
      expect(morning.titleBn, contains('মাছের সকালের খাবার'));

      // Afternoon fish feeding (04:30 PM / 16:30)
      final afternoon = fishSchedules.firstWhere((s) => s.id == 102);
      expect(afternoon.hour, 16);
      expect(afternoon.minute, 30);
      expect(afternoon.titleBn, contains('মাছের বিকালের খাবার'));
    });

    test('Contains valid poultry schedules (Chickens and Ducks)', () {
      final chickenSchedules = FeedingAlarmService.feedingSchedules
          .where((s) => s.type == FeedingTargetType.chicken)
          .toList();
      expect(chickenSchedules.length, 3);

      final duckSchedules = FeedingAlarmService.feedingSchedules
          .where((s) => s.type == FeedingTargetType.duck)
          .toList();
      expect(duckSchedules.length, 3);
    });
  });
}

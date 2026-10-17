import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/availability/availability_models.dart';

void main() {
  group('TimeWindow Model Tests', () {
    test('valid window returns true', () {
      const window = TimeWindow(weekday: 1, startTime: '09:00', endTime: '17:00');
      expect(window.isValid(), isTrue);
      expect(window.weekdayName, 'Tuesday');
      expect(window.weekdayShort, 'Tue');
    });

    test('invalid window where end is before start returns false', () {
      const window = TimeWindow(weekday: 2, startTime: '18:00', endTime: '09:00');
      expect(window.isValid(), isFalse);
    });

    test('invalid weekday returns false', () {
      const window = TimeWindow(weekday: 7, startTime: '09:00', endTime: '10:00');
      expect(window.isValid(), isFalse);
    });
  });

  group('AvailabilityData Model Tests', () {
    test('parses from and to json', () {
      final json = {
        'user_id': 'u123',
        'weekly_capacity': 8,
        'timezone': 'Asia/Kolkata',
        'windows': [
          {'weekday': 0, 'start_time': '10:00', 'end_time': '12:00'}
        ],
        'used_this_week': 2,
        'capacity_left': 6,
      };

      final data = AvailabilityData.fromJson(json);
      expect(data.userId, 'u123');
      expect(data.weeklyCapacity, 8);
      expect(data.capacityLeft, 6);
      expect(data.windows.length, 1);
      expect(data.windows.first.weekdayName, 'Monday');
    });
  });
}

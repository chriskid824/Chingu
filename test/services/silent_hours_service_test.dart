import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chingu/services/silent_hours_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SilentHoursService', () {
    late SilentHoursService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = SilentHoursService();
      await service.init();
    });

    test('Default values should be correct', () {
      expect(service.isEnabled, false);
      expect(service.startTime, const TimeOfDay(hour: 22, minute: 0));
      expect(service.endTime, const TimeOfDay(hour: 7, minute: 0));
    });

    test('isSilentTime returns false when disabled', () {
      // Even in the range (e.g. 23:00), it should be false if disabled
      final now = DateTime(2023, 1, 1, 23, 0);
      expect(service.isSilentTime(now), false);
    });

    test('isSilentTime functionality', () async {
      await service.setEnabled(true);
      await service.setSilentHours(
        const TimeOfDay(hour: 22, minute: 0),
        const TimeOfDay(hour: 7, minute: 0),
      );

      // Case 1: Inside silent hours (night)
      expect(service.isSilentTime(DateTime(2023, 1, 1, 23, 0)), true);

      // Case 2: Inside silent hours (early morning)
      expect(service.isSilentTime(DateTime(2023, 1, 1, 5, 0)), true);

      // Case 3: Outside silent hours (day)
      expect(service.isSilentTime(DateTime(2023, 1, 1, 12, 0)), false);

      // Case 4: Edge case - start time
      expect(service.isSilentTime(DateTime(2023, 1, 1, 22, 0)), true);

      // Case 5: Edge case - just before end time (e.g. 06:59)
      expect(service.isSilentTime(DateTime(2023, 1, 1, 6, 59)), true);
    });

    test('isSilentTime functionality (same day)', () async {
      await service.setEnabled(true);
      await service.setSilentHours(
        const TimeOfDay(hour: 13, minute: 0), // 1 PM
        const TimeOfDay(hour: 15, minute: 0), // 3 PM
      );

      // Inside
      expect(service.isSilentTime(DateTime(2023, 1, 1, 14, 0)), true);

      // Outside
      expect(service.isSilentTime(DateTime(2023, 1, 1, 12, 0)), false);
      expect(service.isSilentTime(DateTime(2023, 1, 1, 16, 0)), false);
    });
  });
}

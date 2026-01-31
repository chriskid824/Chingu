import 'package:chingu/models/dinner_event_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DinnerEventModel', () {
    final now = DateTime.now();
    final event = DinnerEventModel(
      id: 'test_id',
      creatorId: 'user_1',
      dateTime: now,
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
      participantIds: ['user_1'],
      participantStatus: {'user_1': 'confirmed'},
      status: 'pending',
      createdAt: now,
      isReminderSent: true,
    );

    test('should have isReminderSent field', () {
      expect(event.isReminderSent, true);
    });

    test('toMap should include isReminderSent', () {
      final map = event.toMap();
      expect(map['isReminderSent'], true);
    });

    test('fromMap should parse isReminderSent', () {
      final map = event.toMap();
      // toMap converts DateTime to Timestamp, so we don't need to manually do it
      // actually toMap uses Timestamp.fromDate(), so map['dateTime'] is Timestamp.

      final newEvent = DinnerEventModel.fromMap(map, 'test_id');
      expect(newEvent.isReminderSent, true);
    });

    test('default value for isReminderSent should be false', () {
      final defaultEvent = DinnerEventModel(
        id: 'test_id_2',
        creatorId: 'user_2',
        dateTime: now,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        participantIds: ['user_2'],
        participantStatus: {'user_2': 'confirmed'},
        createdAt: now,
      );
      expect(defaultEvent.isReminderSent, false);
      expect(defaultEvent.toMap()['isReminderSent'], false);
    });

    test('copyWith should update isReminderSent', () {
      final updatedEvent = event.copyWith(isReminderSent: false);
      expect(updatedEvent.isReminderSent, false);
    });
  });
}

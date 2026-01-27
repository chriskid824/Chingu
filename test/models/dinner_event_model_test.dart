import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      createdAt: now,
    );

    test('should have isReminderSent default to false', () {
      expect(event.isReminderSent, false);
    });

    test('should serialize isReminderSent to map', () {
      final map = event.toMap();
      expect(map['isReminderSent'], false);
    });

    test('should deserialize isReminderSent from map', () {
      final map = event.toMap();
      map['isReminderSent'] = true;

      // DinnerEventModel.fromMap expects Timestamp objects for date fields
      // because it casts them: (map['dateTime'] as Timestamp).toDate()
      final mapForFromMap = Map<String, dynamic>.from(map);
      mapForFromMap['dateTime'] = Timestamp.fromDate(now);
      mapForFromMap['createdAt'] = Timestamp.fromDate(now);

      final newEvent = DinnerEventModel.fromMap(mapForFromMap, 'test_id');
      expect(newEvent.isReminderSent, true);
    });

    test('copyWith should update isReminderSent', () {
      final newEvent = event.copyWith(isReminderSent: true);
      expect(newEvent.isReminderSent, true);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('DinnerEventModel', () {
    test('should have isReminderSent default to false', () {
      final event = DinnerEventModel(
        id: '1',
        creatorId: 'user1',
        dateTime: DateTime.now(),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        participantIds: ['user1'],
        participantStatus: {'user1': 'confirmed'},
        createdAt: DateTime.now(),
      );

      expect(event.isReminderSent, false);
    });

    test('should serialize isReminderSent in toMap', () {
      final event = DinnerEventModel(
        id: '1',
        creatorId: 'user1',
        dateTime: DateTime.now(),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        participantIds: ['user1'],
        participantStatus: {'user1': 'confirmed'},
        createdAt: DateTime.now(),
        isReminderSent: true,
      );

      final map = event.toMap();
      expect(map['isReminderSent'], true);
    });

    test('should deserialize isReminderSent from Map', () {
      final map = {
        'creatorId': 'user1',
        'dateTime': Timestamp.now(),
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
        'participantIds': ['user1'],
        'participantStatus': {'user1': 'confirmed'},
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'isReminderSent': true,
      };

      final event = DinnerEventModel.fromMap(map, '1');
      expect(event.isReminderSent, true);
    });

    test('should default isReminderSent to false if missing in Map', () {
      final map = {
        'creatorId': 'user1',
        'dateTime': Timestamp.now(),
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
        'participantIds': ['user1'],
        'participantStatus': {'user1': 'confirmed'},
        'status': 'pending',
        'createdAt': Timestamp.now(),
      };

      final event = DinnerEventModel.fromMap(map, '1');
      expect(event.isReminderSent, false);
    });

    test('copyWith should update isReminderSent', () {
      final event = DinnerEventModel(
        id: '1',
        creatorId: 'user1',
        dateTime: DateTime.now(),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        participantIds: ['user1'],
        participantStatus: {'user1': 'confirmed'},
        createdAt: DateTime.now(),
        isReminderSent: false,
      );

      final updated = event.copyWith(isReminderSent: true);
      expect(updated.isReminderSent, true);
      expect(updated.id, event.id);
    });
  });
}

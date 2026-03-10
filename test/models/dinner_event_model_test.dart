import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';

void main() {
  group('DinnerEventModel', () {
    test('should have reminderSent default to false', () {
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

      expect(event.reminderSent, false);
    });

    test('should support reminderSent in fromMap/toMap', () {
      final now = DateTime.now();
      final map = {
        'creatorId': 'user1',
        'dateTime': Timestamp.fromDate(now),
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
        'participantIds': ['user1'],
        'participantStatus': {'user1': 'confirmed'},
        'status': 'pending',
        'createdAt': Timestamp.fromDate(now),
        'reminderSent': true,
      };

      final event = DinnerEventModel.fromMap(map, '1');
      expect(event.reminderSent, true);
      expect(event.toMap()['reminderSent'], true);
    });

    test('copyWith should update reminderSent', () {
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
        reminderSent: false,
      );

      final updatedEvent = event.copyWith(reminderSent: true);
      expect(updatedEvent.reminderSent, true);
    });
  });
}

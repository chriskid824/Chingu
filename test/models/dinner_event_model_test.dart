import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('DinnerEventModel', () {
    final now = DateTime.now();
    final eventId = 'test_event_id';
    final creatorId = 'test_creator_id';

    test('should have default reminder values as false', () {
      final event = DinnerEventModel(
        id: eventId,
        creatorId: creatorId,
        dateTime: now,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        participantIds: ['user1'],
        participantStatus: {'user1': 'confirmed'},
        createdAt: now,
      );

      expect(event.is24hReminderSent, false);
      expect(event.is2hReminderSent, false);
    });

    test('fromMap should correctly deserialize reminder fields', () {
      final map = {
        'creatorId': creatorId,
        'dateTime': Timestamp.fromDate(now),
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
        'participantIds': ['user1'],
        'participantStatus': {'user1': 'confirmed'},
        'createdAt': Timestamp.fromDate(now),
        'is24hReminderSent': true,
        'is2hReminderSent': true,
      };

      final event = DinnerEventModel.fromMap(map, eventId);

      expect(event.is24hReminderSent, true);
      expect(event.is2hReminderSent, true);
    });

    test('toMap should correctly serialize reminder fields', () {
      final event = DinnerEventModel(
        id: eventId,
        creatorId: creatorId,
        dateTime: now,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        participantIds: ['user1'],
        participantStatus: {'user1': 'confirmed'},
        createdAt: now,
        is24hReminderSent: true,
        is2hReminderSent: true,
      );

      final map = event.toMap();

      expect(map['is24hReminderSent'], true);
      expect(map['is2hReminderSent'], true);
    });

    test('copyWith should correctly update reminder fields', () {
      final event = DinnerEventModel(
        id: eventId,
        creatorId: creatorId,
        dateTime: now,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        participantIds: ['user1'],
        participantStatus: {'user1': 'confirmed'},
        createdAt: now,
      );

      final updatedEvent = event.copyWith(
        is24hReminderSent: true,
        is2hReminderSent: true,
      );

      expect(updatedEvent.is24hReminderSent, true);
      expect(updatedEvent.is2hReminderSent, true);
    });
  });
}

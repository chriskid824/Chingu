import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('DinnerEventModel Tests', () {
    final now = DateTime.now();
    final event = DinnerEventModel(
      id: 'test_event',
      creatorId: 'creator_1',
      dateTime: now,
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
      maxParticipants: 6,
      participantIds: ['user1', 'user2'],
      participantStatus: {'user1': 'confirmed', 'user2': 'pending'},
      waitlist: ['user3'],
      status: 'pending',
      createdAt: now,
    );

    test('isFull returns correct boolean', () {
      expect(event.isFull, false);

      final fullEvent = event.copyWith(
        participantIds: ['1', '2', '3', '4', '5', '6']
      );
      expect(fullEvent.isFull, true);
    });

    test('currentParticipants returns correct count', () {
      expect(event.currentParticipants, 2);
    });

    test('getUserRegistrationStatus returns correct status', () {
      expect(event.getUserRegistrationStatus('user1'), EventRegistrationStatus.registered);
      expect(event.getUserRegistrationStatus('user3'), EventRegistrationStatus.waitlist);
      expect(event.getUserRegistrationStatus('user4'), EventRegistrationStatus.none);
    });

    test('toMap and fromMap work correctly', () {
      final map = event.toMap();
      final newEvent = DinnerEventModel.fromMap(map, event.id);

      expect(newEvent.id, event.id);
      expect(newEvent.participantIds, event.participantIds);
      expect(newEvent.waitlist, event.waitlist);
      expect(newEvent.maxParticipants, event.maxParticipants);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('DinnerEventModel', () {
    final now = DateTime.now();
    final event = DinnerEventModel(
      id: 'test_id',
      creatorId: 'creator',
      dateTime: now,
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
      maxParticipants: 6,
      participantIds: ['p1', 'p2'],
      participantStatus: {'p1': 'confirmed', 'p2': 'confirmed'},
      waitlistIds: ['w1'],
      createdAt: now,
    );

    test('should calculate currentParticipantsCount correctly', () {
      expect(event.currentParticipantsCount, 2);
    });

    test('should calculate waitlistCount correctly', () {
      expect(event.waitlistCount, 1);
    });

    test('isFull should be false when participants < max', () {
      expect(event.isFull, false);
    });

    test('isFull should be true when participants >= max', () {
      final fullEvent = event.copyWith(
        participantIds: ['1', '2', '3', '4', '5', '6'],
      );
      expect(fullEvent.isFull, true);
    });

    test('isUserOnWaitlist should return correct boolean', () {
      expect(event.isUserOnWaitlist('w1'), true);
      expect(event.isUserOnWaitlist('p1'), false);
    });
  });
}

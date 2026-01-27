import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService - Join/Leave/Waitlist', () {
    test('joinEvent should add user to participants', () async {
      // Create event
      final eventId = await service.createEvent(
        creatorId: 'creator1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Join
      await service.joinEvent(eventId, 'user2');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, contains('user2'));
      expect(event.participantStatus['user2'], equals('confirmed'));
    });

    test('joinEvent should fail if event is full', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2, // Small limit
      );

      await service.joinEvent(eventId, 'user2');

      // Now full (user1 + user2 = 2)
      expect(
        () => service.joinEvent(eventId, 'user3'),
        throwsA(isA<Exception>()),
      );
    });

    test('joinWaitlist should add user to waitingList', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 1, // Full immediately
      );

      expect(
        () => service.joinEvent(eventId, 'user2'),
        throwsA(isA<Exception>()),
      );

      await service.joinWaitlist(eventId, 'user2');

      final event = await service.getEvent(eventId);
      expect(event!.waitingList, contains('user2'));
      expect(event.participantIds, isNot(contains('user2')));
    });

    test('leaveEvent should remove user from participants', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.joinEvent(eventId, 'user2');
      await service.leaveEvent(eventId, 'user2');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user2')));
    });

    test('leaveEvent should remove user from waitlist', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 1,
      );

      await service.joinWaitlist(eventId, 'user2');
      await service.leaveEvent(eventId, 'user2');

      final event = await service.getEvent(eventId);
      expect(event!.waitingList, isNot(contains('user2')));
    });

    test('joinEvent should fail if deadline passed', () async {
       // Deadline is usually 24h before.
       // So if event is in 12h, deadline passed 12h ago.
       final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(hours: 12)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // By default registrationDeadline is dateTime - 24h.
      // 12h from now - 24h = -12h from now (passed).

      expect(
        () => service.joinEvent(eventId, 'user2'),
        throwsA(isA<Exception>()),
      );
    });
  });
}

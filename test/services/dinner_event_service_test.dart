import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late DinnerEventService dinnerEventService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dinnerEventService = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService', () {
    test('createEvent should create a new event with pending status', () async {
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final eventSnapshot =
          await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(eventSnapshot.exists, true);
      expect(eventSnapshot.data()!['creatorId'], 'user1');
      expect(eventSnapshot.data()!['status'], 'pending');
      expect(eventSnapshot.data()!['participantIds'], ['user1']);
    });

    test('joinEvent should add user to participants if valid', () async {
      // Create event with 1 user
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await dinnerEventService.joinEvent(eventId, 'user2');

      final event = await dinnerEventService.getEvent(eventId);
      expect(event!.participantIds.contains('user2'), true);
      expect(event.participantIds.length, 2);
    });

    test('joinEvent should throw if event is full', () async {
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill the event (already has user1)
      for (var i = 2; i <= 6; i++) {
        await dinnerEventService.joinEvent(eventId, 'user$i');
      }

      final fullEvent = await dinnerEventService.getEvent(eventId);
      expect(fullEvent!.participantIds.length, 6);
      expect(fullEvent.status, EventStatus.confirmed);

      // Try adding 7th user
      expect(
        () => dinnerEventService.joinEvent(eventId, 'user7'),
        throwsA(isA<Exception>()),
      );
    });

    test('joinEvent should throw if deadline passed', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));

      // Manually create event with past deadline to bypass createEvent logic if needed,
      // but createEvent sets deadline to dateTime - 24h.
      // So if we set dateTime to now + 1h, deadline is already passed (now - 23h).

      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(hours: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Force update deadline to past just to be sure
      await fakeFirestore.collection('dinner_events').doc(eventId).update({
        'registrationDeadline': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
      });

      expect(
        () => dinnerEventService.joinEvent(eventId, 'user2'),
        throwsA(isA<Exception>()),
      );
    });

    test('addToWaitlist should add user to waitlist', () async {
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await dinnerEventService.addToWaitlist(eventId, 'user2');

      final event = await dinnerEventService.getEvent(eventId);
      expect(event!.waitlist.contains('user2'), true);
      expect(event.participantIds.contains('user2'), false);
    });

    test('leaveEvent should remove user from participants', () async {
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await dinnerEventService.joinEvent(eventId, 'user2');
      await dinnerEventService.leaveEvent(eventId, 'user2');

      final event = await dinnerEventService.getEvent(eventId);
      expect(event!.participantIds.contains('user2'), false);
    });

    test('leaveEvent should remove user from waitlist', () async {
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await dinnerEventService.addToWaitlist(eventId, 'user2');
      await dinnerEventService.leaveEvent(eventId, 'user2');

      final event = await dinnerEventService.getEvent(eventId);
      expect(event!.waitlist.contains('user2'), false);
    });

    test('Event status should change to confirmed when full', () async {
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      for (var i = 2; i <= 6; i++) {
        await dinnerEventService.joinEvent(eventId, 'user$i');
      }

      final event = await dinnerEventService.getEvent(eventId);
      expect(event!.status, EventStatus.confirmed);
    });

    test('Event status should revert to pending if confirmed and user leaves', () async {
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      for (var i = 2; i <= 6; i++) {
        await dinnerEventService.joinEvent(eventId, 'user$i');
      }

      // Confirm it's confirmed
      var event = await dinnerEventService.getEvent(eventId);
      expect(event!.status, EventStatus.confirmed);

      // User leaves
      await dinnerEventService.leaveEvent(eventId, 'user6');

      event = await dinnerEventService.getEvent(eventId);
      expect(event!.status, EventStatus.pending);
      expect(event.participantIds.length, 5);
    });
  });
}

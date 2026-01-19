import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService eventService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    eventService = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService', () {
    test('createEvent creates an event with correct data', () async {
      final now = DateTime.now();
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: now.add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final data = doc.data()!;

      expect(data['creatorId'], 'user1');
      expect(data['city'], 'Taipei');
      expect(data['participantIds'], ['user1']);
      expect(data['status'], 'pending');

      // Check deadline is 24h before
      final deadline = (data['registrationDeadline'] as Timestamp).toDate();
      // Allow slight difference due to execution time
      final expectedDeadline = now.add(const Duration(days: 1));
      expect(deadline.difference(expectedDeadline).inSeconds.abs() < 5, true);
    });

    test('joinEvent adds user if valid', () async {
      final now = DateTime.now();
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: now.add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await eventService.joinEvent(eventId, 'user2');

      final event = await eventService.getEvent(eventId);
      expect(event!.participantIds, contains('user2'));
      expect(event.participantIds.length, 2);
    });

    test('joinEvent throws if full', () async {
      final now = DateTime.now();
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: now.add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill up to 6 (user1 already there)
      for (var i = 2; i <= 6; i++) {
        await eventService.joinEvent(eventId, 'user$i');
      }

      expect(
        () => eventService.joinEvent(eventId, 'user7'),
        throwsException,
      );
    });

    test('joinWaitlist adds user to waitlist', () async {
      final now = DateTime.now();
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: now.add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await eventService.joinWaitlist(eventId, 'user2');

      final event = await eventService.getEvent(eventId);
      expect(event!.waitingListIds, contains('user2'));
    });

    test('leaveEvent promotes from waitlist', () async {
      final now = DateTime.now();
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: now.add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill up
      for (var i = 2; i <= 6; i++) {
        await eventService.joinEvent(eventId, 'user$i');
      }

      // Add to waitlist
      await eventService.joinWaitlist(eventId, 'waiter1');

      // User 1 leaves
      await eventService.leaveEvent(eventId, 'user1');

      final event = await eventService.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user1')));
      expect(event.participantIds, contains('waiter1'));
      expect(event.waitingListIds, isEmpty);
    });
  });
}

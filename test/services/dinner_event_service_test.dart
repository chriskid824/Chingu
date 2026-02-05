import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService eventService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    eventService = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService', () {
    test('createEvent creates an event', () async {
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 5)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(doc.exists, true);
      expect(doc.data()!['creatorId'], 'user1');
      expect(doc.data()!['status'], EventStatus.pending.name);
    });

    test('joinEvent adds user to participants if not full', () async {
      // Create event
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 5)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await eventService.joinEvent(eventId, 'user2');

      final event = await eventService.getEvent(eventId);
      expect(event!.participantIds.contains('user2'), true);
      expect(event.participantIds.length, 2);
    });

    test('joinEvent adds user to waitlist if full', () async {
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 5)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event
      for (int i = 2; i <= 6; i++) {
        await eventService.joinEvent(eventId, 'user$i');
      }

      final fullEvent = await eventService.getEvent(eventId);
      expect(fullEvent!.participantIds.length, 6);
      expect(fullEvent.status, EventStatus.confirmed);

      // Join 7th user
      await eventService.joinEvent(eventId, 'user7');

      final waitlistedEvent = await eventService.getEvent(eventId);
      expect(waitlistedEvent!.participantIds.length, 6);
      expect(waitlistedEvent.waitlist.contains('user7'), true);
    });

    test('leaveEvent removes user and promotes from waitlist', () async {
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 5)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event + 1 waitlist
      for (int i = 2; i <= 6; i++) {
        await eventService.joinEvent(eventId, 'user$i');
      }
      await eventService.joinEvent(eventId, 'user7'); // In waitlist

      // user1 leaves
      await eventService.leaveEvent(eventId, 'user1');

      final event = await eventService.getEvent(eventId);
      expect(event!.participantIds.contains('user1'), false);
      expect(event.participantIds.contains('user7'), true); // Promoted
      expect(event.waitlist.isEmpty, true);
      expect(event.participantIds.length, 6);
    });

    test('leaveEvent throws exception if within 24 hours', () async {
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(hours: 10)), // < 24h
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      expect(
        () => eventService.leaveEvent(eventId, 'user1'),
        throwsException,
      );
    });

    test('getUserEvents returns events for user', () async {
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 5)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final events = await eventService.getUserEvents('user1');
      expect(events.length, 1);
      expect(events.first.id, eventId);
    });
  });
}

import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService eventService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    eventService = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService Tests', () {
    test('createEvent creates a new event correctly', () async {
      final dateTime = DateTime.now().add(const Duration(days: 2));
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final event = await eventService.getEvent(eventId);
      expect(event, isNotNull);
      expect(event!.creatorId, 'user1');
      expect(event.participantIds.length, 1);
      expect(event.participantIds.first, 'user1');
      expect(event.status, EventStatus.pending);
      expect(event.maxParticipants, 6);
    });

    test('joinEvent allows a user to join', () async {
      final dateTime = DateTime.now().add(const Duration(days: 2));
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await eventService.joinEvent(eventId, 'user2');

      final event = await eventService.getEvent(eventId);
      expect(event!.participantIds.length, 2);
      expect(event.participantIds, contains('user2'));
    });

    test('joinEvent fails if event is full', () async {
      final dateTime = DateTime.now().add(const Duration(days: 2));
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Add 5 more users to fill the event (total 6)
      for (int i = 2; i <= 6; i++) {
        await eventService.joinEvent(eventId, 'user$i');
      }

      // Try to add 7th user
      expect(
        () => eventService.joinEvent(eventId, 'user7'),
        throwsException,
      );
    });

    test('joinWaitlist works when event is full', () async {
      final dateTime = DateTime.now().add(const Duration(days: 2));
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      for (int i = 2; i <= 6; i++) {
        await eventService.joinEvent(eventId, 'user$i');
      }

      await eventService.joinWaitlist(eventId, 'user7');

      final event = await eventService.getEvent(eventId);
      expect(event!.waitingListIds.length, 1);
      expect(event.waitingListIds, contains('user7'));
    });

    test('leaveEvent removes user and promotes waitlist', () async {
      final dateTime = DateTime.now().add(const Duration(days: 2));
      final eventId = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      for (int i = 2; i <= 6; i++) {
        await eventService.joinEvent(eventId, 'user$i');
      }
      await eventService.joinWaitlist(eventId, 'user7');

      // user1 leaves
      await eventService.leaveEvent(eventId, 'user1');

      final event = await eventService.getEvent(eventId);
      expect(event!.participantIds.length, 6);
      expect(event.participantIds, isNot(contains('user1')));
      expect(event.participantIds, contains('user7')); // user7 should be promoted
      expect(event.waitingListIds.isEmpty, true);
    });
  });
}

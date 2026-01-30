import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late DinnerEventService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: firestore);
  });

  group('DinnerEventService', () {
    test('createEvent creates a new event with correct defaults', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final event = await service.getEvent(eventId);
      expect(event, isNotNull);
      expect(event!.creatorId, 'user1');
      expect(event.maxParticipants, 6);
      expect(event.participantIds, contains('user1'));
      expect(event.waitingListIds, isEmpty);
    });

    test('registerForEvent adds user to participants if not full', () async {
      // Create event
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Register user
      await service.registerForEvent(eventId, 'user2');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, contains('user2'));
      expect(event.currentParticipants, 2); // creator + user2
    });

    test('registerForEvent adds user to waitlist if full', () async {
      // Create event
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event (user1 is already there, need 5 more)
      for (int i = 2; i <= 6; i++) {
        await service.registerForEvent(eventId, 'user$i');
      }

      var event = await service.getEvent(eventId);
      expect(event!.currentParticipants, 6);
      expect(event.isFull, true);

      // Register 7th user
      await service.registerForEvent(eventId, 'user7');

      event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user7')));
      expect(event.waitingListIds, contains('user7'));
      expect(event.currentParticipants, 6);
    });

    test('registerForEvent throws if registration deadline passed', () async {
      // Create event in past (deadline passed)
      // Note: we can't easily set creation time in past via createEvent, but we can mock the doc
      final deadline = DateTime.now().subtract(const Duration(hours: 1));

      final event = DinnerEventModel(
        id: 'event_expired',
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(hours: 1)), // event is soon
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        participantIds: ['user1'],
        participantStatus: {'user1': 'confirmed'},
        createdAt: DateTime.now(),
        registrationDeadline: deadline, // Deadline passed
      );

      await firestore.collection('dinner_events').doc('event_expired').set(event.toMap());

      expect(
        () => service.registerForEvent('event_expired', 'user2'),
        throwsException,
      );
    });

    test('unregisterFromEvent promotes from waitlist', () async {
      // Create event
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 5)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event
      for (int i = 2; i <= 6; i++) {
        await service.registerForEvent(eventId, 'user$i');
      }

      // Add to waitlist
      await service.registerForEvent(eventId, 'waitlistUser');

      var event = await service.getEvent(eventId);
      expect(event!.waitingListIds, contains('waitlistUser'));

      // User 2 leaves
      await service.unregisterFromEvent(eventId, 'user2');

      event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user2')));
      expect(event.participantIds, contains('waitlistUser')); // Promoted
      expect(event.waitingListIds, isEmpty);
      expect(event.currentParticipants, 6);
    });

    test('unregisterFromEvent throws if within 24h of event', () async {
      // Event is tomorrow (less than 24h from now? Wait. createEvent logic: deadline is event - 24h)
      // Requirement: "Cancel deadline: 24h before event".
      // So if now > event - 24h (i.e. within 24h), fail.

      final eventTime = DateTime.now().add(const Duration(hours: 20)); // In 20 hours
      // Deadline was 4 hours ago.

      final event = DinnerEventModel(
        id: 'event_soon',
        creatorId: 'user1',
        dateTime: eventTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        participantIds: ['user1', 'user2'],
        participantStatus: {'user1': 'confirmed', 'user2': 'confirmed'},
        createdAt: DateTime.now(),
      );

      await firestore.collection('dinner_events').doc('event_soon').set(event.toMap());

      expect(
        () => service.unregisterFromEvent('event_soon', 'user2'),
        throwsException, // Should throw "Cannot cancel within 24h"
      );
    });
  });
}

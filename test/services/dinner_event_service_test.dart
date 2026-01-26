import 'package:chingu/enums/event_registration_status.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DinnerEventService dinnerEventService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dinnerEventService = DinnerEventService(firestore: fakeFirestore);
  });

  group('createEvent', () {
    test('creates event with correct default values', () async {
      final now = DateTime.now();
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: now,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(doc.exists, true);

      final event = DinnerEventModel.fromMap(doc.data()!, eventId);
      expect(event.maxParticipants, 6);
      expect(event.currentParticipants, 1);
      expect(event.participantIds, ['user1']);
      expect(event.participantStatus['user1'], EventRegistrationStatus.registered.name);
      expect(event.status, 'pending');
    });
  });

  group('registerForEvent', () {
    late String eventId;
    final DateTime eventTime = DateTime.now().add(const Duration(days: 3));

    setUp(() async {
      eventId = await dinnerEventService.createEvent(
        creatorId: 'creator',
        dateTime: eventTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2, // Set small capacity for testing
      );
    });

    test('successfully registers user', () async {
      await dinnerEventService.registerForEvent(eventId, 'user2');

      final event = await dinnerEventService.getEvent(eventId);
      expect(event!.participantIds, contains('user2'));
      expect(event.currentParticipants, 2);
      expect(event.participantStatus['user2'], EventRegistrationStatus.registered.name);
    });

    test('adds user to waitlist when full', () async {
      // Fill the event (creator + user2 = 2, which is max)
      await dinnerEventService.registerForEvent(eventId, 'user2');

      // Try to register user3
      await dinnerEventService.registerForEvent(eventId, 'user3');

      final event = await dinnerEventService.getEvent(eventId);
      expect(event!.participantIds.length, 2);
      expect(event.waitlistIds, contains('user3'));
      expect(event.participantStatus['user3'], EventRegistrationStatus.waitlist.name);
    });

    test('throws exception if duplicate registration', () async {
      await expectLater(
        dinnerEventService.registerForEvent(eventId, 'creator'),
        throwsException,
      );
    });

    test('throws exception if registration deadline passed', () async {
      // Create past event logic simulation?
      // Need to modify event deadline manually in fake firestore
      await fakeFirestore.collection('dinner_events').doc(eventId).update({
        'registrationDeadline': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
      });

      await expectLater(
        dinnerEventService.registerForEvent(eventId, 'user2'),
        throwsException,
      );
    });

    test('throws exception if time conflict exists', () async {
      // User registers for this event
      await dinnerEventService.registerForEvent(eventId, 'user2');

      // Create another event at same time
      final eventId2 = await dinnerEventService.createEvent(
        creatorId: 'other',
        dateTime: eventTime, // Same time
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Try to register for second event
      // Note: _hasTimeConflict logic in service checks query results.
      // FakeFirestore supports queries so it should work.

      await expectLater(
        dinnerEventService.registerForEvent(eventId2, 'user2'),
        throwsException,
      );
    });
  });

  group('unregisterFromEvent', () {
    late String eventId;
    final DateTime eventTime = DateTime.now().add(const Duration(days: 3));

    setUp(() async {
      eventId = await dinnerEventService.createEvent(
        creatorId: 'creator',
        dateTime: eventTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2,
      );
    });

    test('successfully unregisters participant', () async {
      await dinnerEventService.registerForEvent(eventId, 'user2');

      await dinnerEventService.unregisterFromEvent(eventId, 'user2');

      final event = await dinnerEventService.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user2')));
      expect(event.currentParticipants, 1); // Only creator left
    });

    test('promotes waitlist user when participant unregisters', () async {
      // Fill event
      await dinnerEventService.registerForEvent(eventId, 'user2');
      // Add waitlist
      await dinnerEventService.registerForEvent(eventId, 'user3');

      // Unregister user2
      await dinnerEventService.unregisterFromEvent(eventId, 'user2');

      final event = await dinnerEventService.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user2')));
      expect(event.participantIds, contains('user3')); // Promoted
      expect(event.waitlistIds, isEmpty);
      expect(event.participantStatus['user3'], EventRegistrationStatus.registered.name);
    });

    test('throws exception if within 24 hours (cancellation deadline)', () async {
      // Manually set event time to 12 hours from now
      final soon = DateTime.now().add(const Duration(hours: 12));
      await fakeFirestore.collection('dinner_events').doc(eventId).update({
        'dateTime': Timestamp.fromDate(soon),
      });

      await dinnerEventService.registerForEvent(eventId, 'user2');

      // Wait.. registerForEvent might read old data if I don't be careful?
      // No, createEvent made it days away. I updated it.
      // But registerForEvent checks deadline? No, cancellation check is in unregister.

      await expectLater(
        dinnerEventService.unregisterFromEvent(eventId, 'user2'),
        throwsException,
      );
    });
  });

  group('getUserEvents', () {
    test('fetches registered and waitlisted events correctly', () async {
      final now = DateTime.now();
      // Event 1: user is creator (registered)
      await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: now.add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Event 2: user is waitlisted
      final event2 = await dinnerEventService.createEvent(
        creatorId: 'other',
        dateTime: now.add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 1,
      );
      await dinnerEventService.registerForEvent(event2, 'user1'); // Should go to waitlist

      // Fetch
      final events = await dinnerEventService.getUserEvents('user1', includeWaitlist: true);

      expect(events.length, 2);
      expect(events.any((e) => e.participantIds.contains('user1')), true);
      expect(events.any((e) => e.waitlistIds.contains('user1')), true);
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService eventService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    eventService = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService - Registration', () {
    test('registerForEvent successfully adds user to participants', () async {
      // Create an event
      final eventId = await eventService.createEvent(
        creatorId: 'creator_1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Register user
      await eventService.registerForEvent(eventId, 'user_1');

      // Verify
      final event = await eventService.getEvent(eventId);
      expect(event!.participantIds, contains('user_1'));
      expect(event.waitlist, isEmpty);
    });

    test('registerForEvent adds to waitlist if full', () async {
      // Create event with max 1 participant for testing
      final eventId = await eventService.createEvent(
        creatorId: 'user_1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 1,
      );

      // Try to register another user
      await eventService.registerForEvent(eventId, 'user_2');

      // Verify
      final event = await eventService.getEvent(eventId);
      expect(event!.participantIds, equals(['user_1'])); // Creator is participant 1
      expect(event.waitlist, contains('user_2'));
    });

    test('registerForEvent throws if user already registered', () async {
      final eventId = await eventService.createEvent(
        creatorId: 'user_1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Try to register creator again (creator is auto-registered)
      expect(
        () => eventService.registerForEvent(eventId, 'user_1'),
        throwsException,
      );
    });

    test('registerForEvent throws if time conflict exists', () async {
      final now = DateTime.now();
      final eventTime = now.add(const Duration(days: 3));

      // User registered for event A
      await eventService.createEvent(
        creatorId: 'user_1',
        dateTime: eventTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Create event B at same time
      final eventBId = await eventService.createEvent(
        creatorId: 'user_2',
        dateTime: eventTime.add(const Duration(minutes: 30)), // Same day
        budgetRange: 1,
        city: 'Taipei',
        district: 'Da-an',
      );

      // User 1 tries to register for event B
      // Note: _checkTimeConflict logic relies on getUserEvents
      expect(
        () => eventService.registerForEvent(eventBId, 'user_1'),
        throwsException, // Should throw time conflict exception
      );
    });
  });

  group('DinnerEventService - Unregistration', () {
    test('unregisterFromEvent removes user successfully', () async {
      final eventId = await eventService.createEvent(
        creatorId: 'user_1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await eventService.registerForEvent(eventId, 'user_2');

      await eventService.unregisterFromEvent(eventId, 'user_2');

      final event = await eventService.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user_2')));
    });

    test('unregisterFromEvent promotes waitlist user', () async {
      final eventId = await eventService.createEvent(
        creatorId: 'user_1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 1, // Only 1 allowed
      );

      // user_2 -> Waitlist (since user_1 took spot)
      await eventService.registerForEvent(eventId, 'user_2');

      final preEvent = await eventService.getEvent(eventId);
      expect(preEvent!.waitlist, contains('user_2'));

      // user_1 cancels
      await eventService.unregisterFromEvent(eventId, 'user_1');

      // Verify user_2 promoted
      final postEvent = await eventService.getEvent(eventId);
      expect(postEvent!.participantIds, contains('user_2'));
      expect(postEvent.waitlist, isEmpty);
    });

    test('unregisterFromEvent throws if < 24 hours', () async {
      final eventId = await eventService.createEvent(
        creatorId: 'user_1',
        dateTime: DateTime.now().add(const Duration(hours: 20)), // < 24h
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      expect(
        () => eventService.unregisterFromEvent(eventId, 'user_1'),
        throwsException,
      );
    });
  });
}

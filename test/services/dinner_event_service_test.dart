import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService Registration', () {
    test('registerForEvent adds user to participants when space available', () async {
      // Arrange
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Act
      await service.registerForEvent(eventId, 'user1');

      // Assert
      final event = await service.getEvent(eventId);
      expect(event!.participantIds, contains('user1'));
      expect(event.participantStatus['user1'], equals(EventRegistrationStatus.registered.name));
    });

    test('registerForEvent adds user to waitlist when full', () async {
      // Arrange
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill up the event (creator + 5 others)
      for (int i = 0; i < 5; i++) {
        await service.joinEvent(eventId, 'user$i');
        // Note: joinEvent is the old method, we assume it fills participantIds
        // Or we can manually update firestore to simulate full event
      }

      // Verify full
      final fullEvent = await service.getEvent(eventId);
      expect(fullEvent!.participantIds.length, 6);

      // Act: Try to register 7th person
      await service.registerForEvent(eventId, 'waitlistUser');

      // Assert
      final event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('waitlistUser')));
      expect(event.waitingList, contains('waitlistUser'));
      expect(event.participantStatus['waitlistUser'], equals(EventRegistrationStatus.waitlist.name));
    });

    test('registerForEvent throws on duplicate registration', () async {
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.registerForEvent(eventId, 'user1');

      expect(
        () => service.registerForEvent(eventId, 'user1'),
        throwsException,
      );
    });

    test('registerForEvent throws on time conflict', () async {
      final time = DateTime.now().add(const Duration(days: 2));

      // Event 1
      final eventId1 = await service.createEvent(
        creatorId: 'creator',
        dateTime: time,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Event 2 (Same time)
      final eventId2 = await service.createEvent(
        creatorId: 'creator2',
        dateTime: time,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Da-an',
      );

      await service.registerForEvent(eventId1, 'user1');

      expect(
        () => service.registerForEvent(eventId2, 'user1'),
        throwsException,
      );
    });
  });

  group('DinnerEventService Unregistration', () {
    test('unregisterFromEvent removes user', () async {
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.registerForEvent(eventId, 'user1');

      await service.unregisterFromEvent(eventId, 'user1');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user1')));
    });

    test('unregisterFromEvent promotes waitlist user', () async {
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event
      for (int i = 0; i < 5; i++) {
        await service.joinEvent(eventId, 'user$i');
      }

      // Add to waitlist
      await service.registerForEvent(eventId, 'waitlistUser');

      // Remove a participant
      await service.unregisterFromEvent(eventId, 'user0');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, contains('waitlistUser'));
      expect(event.waitingList, isNot(contains('waitlistUser')));
      expect(event.participantStatus['waitlistUser'], equals(EventRegistrationStatus.registered.name));
    });

    test('unregisterFromEvent throws if within 24 hours', () async {
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(hours: 23)), // < 24h
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.registerForEvent(eventId, 'user1');

      expect(
        () => service.unregisterFromEvent(eventId, 'user1'),
        throwsException,
      );
    });
  });
}

import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService Registration', () {
    test('registerForEvent adds user to participants when not full', () async {
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
      expect(event.participantStatus['user1'], 'confirmed');
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

      // Fill event (creator + 5 users = 6 max)
      for (var i = 1; i <= 5; i++) {
        await service.registerForEvent(eventId, 'user$i');
      }

      // Act
      await service.registerForEvent(eventId, 'waitlist_user');

      // Assert
      final event = await service.getEvent(eventId);
      expect(event!.participantIds.length, 6);
      expect(event.waitingListIds, contains('waitlist_user'));
      expect(event.participantIds, isNot(contains('waitlist_user')));
    });

    test('registerForEvent throws exception for duplicates', () async {
      // Arrange
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );
      await service.registerForEvent(eventId, 'user1');

      // Act & Assert
      expect(
        () => service.registerForEvent(eventId, 'user1'),
        throwsException,
      );
    });
  });

  group('DinnerEventService Unregistration', () {
    test('unregisterFromEvent removes user', () async {
      // Arrange
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );
      await service.registerForEvent(eventId, 'user1');

      // Act
      await service.unregisterFromEvent(eventId, 'user1');

      // Assert
      final event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user1')));
    });

    test('unregisterFromEvent promotes waitlisted user', () async {
      // Arrange
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event
      for (var i = 1; i <= 5; i++) {
        await service.registerForEvent(eventId, 'user$i');
      }
      // Add waiter
      await service.registerForEvent(eventId, 'waiter');

      // Act: user1 leaves
      await service.unregisterFromEvent(eventId, 'user1');

      // Assert
      final event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user1')));
      expect(event.participantIds, contains('waiter')); // Promoted
      expect(event.waitingListIds, isEmpty);
      expect(event.participantStatus['waiter'], 'confirmed');
    });

    test('unregisterFromEvent throws if within 24 hours', () async {
      // Arrange
      // Create event 23 hours from now
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(hours: 23)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Act & Assert
      // Creator tries to leave (creator is automatically added)
      expect(
        () => service.unregisterFromEvent(eventId, 'creator'),
        throwsException,
      );
    });
  });
}

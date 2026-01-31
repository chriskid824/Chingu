import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('DinnerEventService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DinnerEventService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = DinnerEventService(firestore: fakeFirestore);
    });

    test('registerForEvent adds user to participantIds when not full', () async {
      // Arrange
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2,
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
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 1, // Full after creator
      );

      // Act
      await service.registerForEvent(eventId, 'user1');

      // Assert
      final event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user1')));
      expect(event.waitlist, contains('user1'));
    });

    test('registerForEvent throws if already registered', () async {
      // Arrange
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Act & Assert
      expect(
        () => service.registerForEvent(eventId, 'creator'),
        throwsException,
      );
    });

    test('registerForEvent throws if time conflict exists', () async {
      // Arrange
      final time = DateTime.now().add(const Duration(days: 3));

      // Event 1: User 1 is registered
      final event1 = await service.createEvent(
        creatorId: 'user1',
        dateTime: time,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Event 2: Same time
      final event2 = await service.createEvent(
        creatorId: 'creator',
        dateTime: time,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Da-an',
      );

      // Act & Assert
      // User 1 tries to register for Event 2
      expect(
        () => service.registerForEvent(event2, 'user1'),
        throwsException,
      );
    });

    test('unregisterFromEvent promotes from waitlist', () async {
      // Arrange
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 1,
      );

      // User 1 joins waitlist (since creator takes spot 1)
      await service.registerForEvent(eventId, 'user1');

      var event = await service.getEvent(eventId);
      expect(event!.waitlist, contains('user1'));

      // Act: Creator leaves
      await service.unregisterFromEvent(eventId, 'creator');

      // Assert
      event = await service.getEvent(eventId);
      expect(event!.participantIds, contains('user1')); // User1 promoted
      expect(event.waitlist, isEmpty);
      expect(event.participantStatus['user1'], 'confirmed');
    });

    test('unregisterFromEvent throws if < 24h', () async {
       // Arrange
      final eventId = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(hours: 23)), // < 24h
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Act & Assert
      expect(
        () => service.unregisterFromEvent(eventId, 'creator'),
        throwsException,
      );
    });
  });
}

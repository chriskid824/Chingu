import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/enums/event_status.dart';
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

  group('DinnerEventService', () {
    test('createEvent should create a new event correctly', () async {
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime(2025, 12, 25, 19, 0),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 6,
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['creatorId'], 'user1');
      expect(data['maxParticipants'], 6);
      expect((data['participantIds'] as List).length, 1);
      expect(data['status'], EventStatus.pending.name);
    });

    test('joinEvent should add user to participants if not full', () async {
      // Arrange
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 6,
      );

      // Act
      await dinnerEventService.joinEvent(eventId, 'user2');

      // Assert
      final event = await dinnerEventService.getEvent(eventId);
      expect(event!.participantIds, contains('user2'));
      expect(event.participantStatus['user2'], 'confirmed');
    });

    test('joinEvent should add user to waitlist if full', () async {
      // Arrange
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2, // Set small limit
      );

      await dinnerEventService.joinEvent(eventId, 'user2'); // Full now (1+1=2)

      // Act
      await dinnerEventService.joinEvent(eventId, 'user3'); // Should go to waitlist

      // Assert
      final event = await dinnerEventService.getEvent(eventId);
      expect(event!.participantIds.length, 2);
      expect(event.waitingList, contains('user3'));
      expect(event.participantIds, isNot(contains('user3')));
    });

    test('leaveEvent should remove user from participants', () async {
      // Arrange
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );
      await dinnerEventService.joinEvent(eventId, 'user2');

      // Act
      await dinnerEventService.leaveEvent(eventId, 'user2');

      // Assert
      final event = await dinnerEventService.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user2')));
    });

    test('leaveEvent should promote waiter to participant', () async {
      // Arrange
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2,
      );
      await dinnerEventService.joinEvent(eventId, 'user2'); // Full
      await dinnerEventService.joinEvent(eventId, 'user3'); // Waitlist

      // Act: user2 leaves
      await dinnerEventService.leaveEvent(eventId, 'user2');

      // Assert
      final event = await dinnerEventService.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user2')));
      expect(event.participantIds, contains('user3')); // user3 promoted
      expect(event.waitingList, isEmpty);
      expect(event.participantStatus['user3'], 'confirmed');
    });

    test('joinEvent should throw exception if deadline passed', () async {
      // Arrange
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        registrationDeadline: DateTime.now().subtract(const Duration(hours: 1)), // Past
      );

      // Act & Assert
      expect(
        () => dinnerEventService.joinEvent(eventId, 'user2'),
        throwsException,
      );
    });
  });
}

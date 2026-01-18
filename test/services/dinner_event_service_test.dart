import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_status.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService', () {
    test('createEvent creates a valid event', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['creatorId'], 'user1');
      expect(data['status'], 'pending');
      expect(data['maxParticipants'], 6);
      expect((data['participantIds'] as List).length, 1);
    });

    test('joinEvent adds user to participants', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.joinEvent(eventId, 'user2');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, contains('user2'));
      expect(event.participantStatus['user2'], 'confirmed');
    });

    test('joinEvent throws if full', () async {
      // Create event with max 2 participants
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2,
      );

      await service.joinEvent(eventId, 'user2');

      expect(
        () => service.joinEvent(eventId, 'user3'),
        throwsException,
      );
    });

    test('joinEvent updates status to confirmed when full', () async {
       final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2,
      );

      await service.joinEvent(eventId, 'user2');

      final event = await service.getEvent(eventId);
      expect(event!.status, EventStatus.confirmed);
    });

    test('joinWaitlist adds user to waitlist', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.joinWaitlist(eventId, 'userWait');

      final event = await service.getEvent(eventId);
      expect(event!.waitlist, contains('userWait'));
    });

    test('leaveEvent removes user', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.joinEvent(eventId, 'user2');
      await service.leaveEvent(eventId, 'user2');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user2')));
    });

    test('leaveEvent promotes user from waitlist', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2,
      );

      await service.joinEvent(eventId, 'user2'); // Full
      await service.joinWaitlist(eventId, 'userWait');

      await service.leaveEvent(eventId, 'user2');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user2')));
      expect(event.participantIds, contains('userWait'));
      expect(event.waitlist, isEmpty);
      expect(event.participantStatus['userWait'], 'confirmed');
    });

    test('createEvent defaults deadline correctly', () async {
      final dateTime = DateTime.now().add(const Duration(days: 2));
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final event = await service.getEvent(eventId);
      // Deadline should be dateTime - 24h
      final expectedDeadline = dateTime.subtract(const Duration(hours: 24));
      expect(
        event!.registrationDeadline.isAtSameMomentAs(expectedDeadline),
        true
      );
    });
  });
}

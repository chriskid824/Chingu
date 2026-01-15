import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService', () {
    test('createEvent should create event with correct defaults', () async {
      final dateTime = DateTime.now().add(const Duration(days: 3));
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final eventSnapshot = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final event = DinnerEventModel.fromMap(eventSnapshot.data()!, eventSnapshot.id);

      expect(event.creatorId, 'user1');
      expect(event.participantIds, ['user1']);
      expect(event.participantStatus['user1'], 'confirmed');
      expect(event.waitlistIds, isEmpty);
      expect(event.status, EventStatus.pending);
      // Deadline should be approx 24 hours before event
      expect(
        event.registrationDeadline.difference(dateTime.subtract(const Duration(hours: 24))).inSeconds.abs() < 5,
        true,
      );
    });

    test('joinEvent should allow joining and update status', () async {
      final dateTime = DateTime.now().add(const Duration(days: 3));
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.joinEvent(eventId, 'user2');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, contains('user2'));
      expect(event.participantStatus['user2'], 'confirmed');
      expect(event.status, EventStatus.pending);
    });

    test('joinEvent should fail if full', () async {
      final dateTime = DateTime.now().add(const Duration(days: 3));
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill up to 6
      for (int i = 2; i <= 6; i++) {
        await service.joinEvent(eventId, 'user$i');
      }

      final event = await service.getEvent(eventId);
      expect(event!.participantIds.length, 6);
      expect(event.status, EventStatus.confirmed); // Should auto confirm

      // Try joining 7th
      expect(
        () => service.joinEvent(eventId, 'user7'),
        throwsException,
      );
    });

    test('joinWaitlist should add to waitlist', () async {
      final dateTime = DateTime.now().add(const Duration(days: 3));
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Make full first (usually you join waitlist when full, but service doesn't enforce "must be full to waitlist" explicitly, but UI does. Service allows waitlist even if not full? Let's check logic. The service allows joinWaitlist anytime unless already participant.)
      // Wait, `joinWaitlist` doesn't check if full. That's fine.

      await service.joinWaitlist(eventId, 'userWait1');

      final event = await service.getEvent(eventId);
      expect(event!.waitlistIds, contains('userWait1'));
    });

    test('leaveEvent should promote waitlist user', () async {
      final dateTime = DateTime.now().add(const Duration(days: 3));
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.joinWaitlist(eventId, 'userWait1');

      // user1 leaves
      await service.leaveEvent(eventId, 'user1');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user1')));
      expect(event.participantIds, contains('userWait1')); // Promoted
      expect(event.waitlistIds, isEmpty);
      expect(event.participantStatus['userWait1'], 'confirmed');
    });

    test('status should change back to pending if user leaves confirmed event', () async {
      final dateTime = DateTime.now().add(const Duration(days: 3));
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill up to 6
      for (int i = 2; i <= 6; i++) {
        await service.joinEvent(eventId, 'user$i');
      }

      var event = await service.getEvent(eventId);
      expect(event!.status, EventStatus.confirmed);

      // user6 leaves
      await service.leaveEvent(eventId, 'user6');

      event = await service.getEvent(eventId);
      expect(event!.status, EventStatus.pending);
      expect(event.participantIds.length, 5);
    });

    test('getUserEvents should return events where user is participant or waitlisted', () async {
      final dateTime = DateTime.now().add(const Duration(days: 3));
      // Event 1: Participant
      final eventId1 = await service.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Event 2: Waitlisted
      final eventId2 = await service.createEvent(
        creatorId: 'user2',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );
      await service.joinWaitlist(eventId2, 'user1');

      final events = await service.getUserEvents('user1');
      expect(events.length, 2);
      expect(events.any((e) => e.id == eventId1), true);
      expect(events.any((e) => e.id == eventId2), true);
    });
  });
}

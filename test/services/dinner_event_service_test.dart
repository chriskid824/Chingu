import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('DinnerEventService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DinnerEventService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = DinnerEventService(firestore: fakeFirestore);
    });

    test('createEvent creates a document with correct fields', () async {
      final deadline = DateTime.now().add(const Duration(days: 2));
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        registrationDeadline: deadline,
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final data = doc.data()!;

      expect(data['creatorId'], 'user1');
      expect(data['status'], 'pending');
      expect((data['registrationDeadline'] as Timestamp).toDate(), deadline);
      expect((data['participantIds'] as List).length, 1);
      expect((data['participantIds'] as List).first, 'user1');
    });

    test('joinEvent adds user to participants if not full', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.joinEvent(eventId, 'user2');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, contains('user2'));
      expect(event.participantIds.length, 2);
    });

    test('joinEvent adds user to waitlist if full', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill up to 6
      for (int i = 2; i <= 6; i++) {
        await service.joinEvent(eventId, 'user$i');
      }

      final eventFull = await service.getEvent(eventId);
      expect(eventFull!.participantIds.length, 6);
      expect(eventFull.status, EventStatus.confirmed); // Should be auto-confirmed

      // Join 7th user
      await service.joinEvent(eventId, 'user7');

      final eventWaitlist = await service.getEvent(eventId);
      expect(eventWaitlist!.participantIds.length, 6);
      expect(eventWaitlist.waitlistIds, contains('user7'));
      expect(eventWaitlist.waitlistIds.length, 1);
    });

    test('joinEvent throws if deadline passed', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        registrationDeadline: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(
        () => service.joinEvent(eventId, 'user2'),
        throwsException,
      );
    });

    test('leaveEvent promotes from waitlist', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill up to 6
      for (int i = 2; i <= 6; i++) {
        await service.joinEvent(eventId, 'user$i');
      }
      // Add user7 to waitlist
      await service.joinEvent(eventId, 'user7');

      // User 1 leaves
      await service.leaveEvent(eventId, 'user1');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user1')));
      expect(event.participantIds, contains('user7')); // Promoted
      expect(event.participantIds.length, 6);
      expect(event.waitlistIds, isEmpty);
    });

    test('leaveEvent just removes if in waitlist', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill up to 6
      for (int i = 2; i <= 6; i++) {
        await service.joinEvent(eventId, 'user$i');
      }
      // Add user7 to waitlist
      await service.joinEvent(eventId, 'user7');

      // User 7 leaves
      await service.leaveEvent(eventId, 'user7');

      final event = await service.getEvent(eventId);
      expect(event!.waitlistIds, isEmpty);
      expect(event.participantIds.length, 6);
    });
  });
}

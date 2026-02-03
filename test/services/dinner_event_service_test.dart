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
    test('createEvent creates a document with correct initial data', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        notes: 'Test event',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['creatorId'], 'user1');
      expect(data['status'], EventStatus.pending.name);
      expect((data['participantIds'] as List).length, 1);
      expect((data['waitingListIds'] as List).isEmpty, true);
    });

    test('joinEvent adds user to participants if not full', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.joinEvent(eventId, 'user2');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds.contains('user2'), true);
      expect(event.participantIds.length, 2);
    });

    test('joinEvent adds user to waiting list if full', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill the event (user1 is already there)
      for (int i = 2; i <= 6; i++) {
        await service.joinEvent(eventId, 'user$i');
      }

      final fullEvent = await service.getEvent(eventId);
      expect(fullEvent!.participantIds.length, 6);
      expect(fullEvent.status, EventStatus.confirmed); // It becomes confirmed when full (based on implementation)

      // Join with user7
      await service.joinEvent(eventId, 'user7');

      final eventWithWaitlist = await service.getEvent(eventId);
      expect(eventWithWaitlist!.waitingListIds.contains('user7'), true);
      expect(eventWithWaitlist.participantIds.contains('user7'), false);
    });

    test('cancelRegistration removes user and promotes from waiting list', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event
      for (int i = 2; i <= 6; i++) {
        await service.joinEvent(eventId, 'user$i');
      }
      // Add one to waitlist
      await service.joinEvent(eventId, 'user7');

      // user2 cancels
      await service.cancelRegistration(eventId, 'user2');

      final event = await service.getEvent(eventId);

      // user2 should be gone
      expect(event!.participantIds.contains('user2'), false);

      // user7 should be promoted to participants
      expect(event.participantIds.contains('user7'), true);
      expect(event.waitingListIds.contains('user7'), false);

      // Still full/confirmed
      expect(event.participantIds.length, 6);
    });

    test('joinEvent throws if deadline passed', () async {
       final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(hours: 48)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        registrationDeadline: DateTime.now().subtract(const Duration(hours: 1)), // Deadline passed
      );

      expect(
        () => service.joinEvent(eventId, 'user2'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('報名已截止'))),
      );
    });
  });
}

import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_status.dart';
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

  group('DinnerEventService Tests', () {
    test('createEvent creates an event with default deadline', () async {
      final dateTime = DateTime.now().add(const Duration(days: 3));
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final event = DinnerEventModel.fromMap(doc.data()!, doc.id);

      expect(event.creatorId, 'user1');
      expect(event.status, EventStatus.pending);
      // Deadline should be 24h before event
      expect(
        event.registrationDeadline.isAtSameMomentAs(dateTime.subtract(const Duration(hours: 24))),
        true,
      );
    });

    test('joinEvent adds user to participants if not full', () async {
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
      expect(event.participantIds.length, 2);
    });

    test('joinEvent throws if deadline passed', () async {
      final dateTime = DateTime.now().add(const Duration(days: 1)); // Event in 24h
      // Deadline default is 24h before, so deadline is NOW.
      // Wait a bit or set deadline manually? createEvent sets it to dateTime - 24h.
      // If dateTime is now + 10 hours. Deadline was 14 hours ago.

      final pastDateTime = DateTime.now().add(const Duration(hours: 10));
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: pastDateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // The deadline is pastDateTime - 24h = Now - 14h. So it's passed.

      expect(
        () => service.joinEvent(eventId, 'user2'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('報名已截止'))),
      );
    });

    test('joinEvent adds to waitlist if full', () async {
      final dateTime = DateTime.now().add(const Duration(days: 3));
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill the event (already has user1)
      await service.joinEvent(eventId, 'user2');
      await service.joinEvent(eventId, 'user3');
      await service.joinEvent(eventId, 'user4');
      await service.joinEvent(eventId, 'user5');
      await service.joinEvent(eventId, 'user6'); // 6 users now

      final fullEvent = await service.getEvent(eventId);
      expect(fullEvent!.participantIds.length, 6);
      expect(fullEvent.status, EventStatus.confirmed); // Should be confirmed when full

      // Try to join as user7
      await service.joinEvent(eventId, 'user7');

      final eventWithWaitlist = await service.getEvent(eventId);
      expect(eventWithWaitlist!.waitingListIds, contains('user7'));
      expect(eventWithWaitlist.participantIds, isNot(contains('user7')));
    });

    test('leaveEvent promotes user from waitlist', () async {
      final dateTime = DateTime.now().add(const Duration(days: 3));
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event + waitlist
      for (int i = 2; i <= 6; i++) {
        await service.joinEvent(eventId, 'user$i');
      }
      await service.joinEvent(eventId, 'wait1'); // On waitlist

      var event = await service.getEvent(eventId);
      expect(event!.waitingListIds, contains('wait1'));
      expect(event.participantIds, isNot(contains('wait1')));

      // user1 leaves
      await service.leaveEvent(eventId, 'user1');

      event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user1')));
      expect(event.participantIds, contains('wait1')); // Promoted
      expect(event.waitingListIds, isEmpty);
      expect(event.participantStatus['wait1'], 'confirmed');
    });

     test('leaveEvent updates status if not full and no waitlist', () async {
      final dateTime = DateTime.now().add(const Duration(days: 3));
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event
      for (int i = 2; i <= 6; i++) {
        await service.joinEvent(eventId, 'user$i');
      }

      var event = await service.getEvent(eventId);
      expect(event!.status, EventStatus.confirmed);

      // user1 leaves
      await service.leaveEvent(eventId, 'user1');

      event = await service.getEvent(eventId);
      expect(event!.status, EventStatus.pending); // Back to pending because < 6
      expect(event.participantIds.length, 5);
    });
  });
}

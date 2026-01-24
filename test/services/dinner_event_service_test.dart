import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService Tests', () {
    test('createEvent creates an event with pending status', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final event = DinnerEventModel.fromMap(doc.data()!, doc.id);

      expect(event.creatorId, 'user1');
      expect(event.status, EventStatus.pending);
      expect(event.participantIds, contains('user1'));
    });

    test('registerForEvent adds user to participants if not full', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.registerForEvent(eventId, 'user2');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, contains('user2'));
      expect(event.participantIds.length, 2);
    });

    test('registerForEvent adds user to waitlist if full', () async {
      // Create event with user1
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Add 5 more users to fill the table (total 6)
      for (int i = 2; i <= 6; i++) {
        await service.registerForEvent(eventId, 'user$i');
      }

      final fullEvent = await service.getEvent(eventId);
      expect(fullEvent!.participantIds.length, 6);
      expect(fullEvent.status, EventStatus.confirmed); // Should be confirmed now

      // Add 7th user (should go to waitlist)
      await service.registerForEvent(eventId, 'user7');

      final waitlistedEvent = await service.getEvent(eventId);
      expect(waitlistedEvent!.participantIds.length, 6);
      expect(waitlistedEvent.participantIds, isNot(contains('user7')));
      expect(waitlistedEvent.waitlistIds, contains('user7'));
    });

    test('unregisterFromEvent promotes waitlisted user', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event
      for (int i = 2; i <= 6; i++) {
        await service.registerForEvent(eventId, 'user$i');
      }

      // Add waitlist
      await service.registerForEvent(eventId, 'user7');

      // user1 (creator) leaves
      await service.unregisterFromEvent(eventId, 'user1');

      final event = await service.getEvent(eventId);

      // user1 gone
      expect(event!.participantIds, isNot(contains('user1')));

      // user7 promoted
      expect(event.participantIds, contains('user7'));
      expect(event.waitlistIds, isEmpty);
      expect(event.participantStatus['user7'], 'confirmed');
    });

    test('registerForEvent throws error if deadline passed', () async {
       // Create event in the past (deadline passed)
       // Logic sets deadline to dateTime - 24h
       // So if dateTime is now - 1h, deadline was yesterday.

       // However, we can't easily force createEvent to accept a past date for deadline
       // because it calculates it internally based on dateTime.
       // Let's create an event manually in Firestore to control fields.

       final deadline = DateTime.now().subtract(const Duration(hours: 1));
       final eventId = 'expired_event';

       await fakeFirestore.collection('dinner_events').doc(eventId).set({
         'creatorId': 'user1',
         'dateTime': Timestamp.fromDate(DateTime.now()),
         'registrationDeadline': Timestamp.fromDate(deadline),
         'participantIds': ['user1'],
         'participantStatus': {'user1': 'confirmed'},
         'waitlistIds': [],
         'status': 'pending',
         'createdAt': Timestamp.now(),
         'budgetRange': 1,
         'city': 'Taipei',
         'district': 'Xinyi',
       });

       expect(
         () => service.registerForEvent(eventId, 'user2'),
         throwsException,
       );
    });
  });
}

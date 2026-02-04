import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService eventService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    eventService = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService', () {
    test('createEvent creates an event', () async {
      final id = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      expect(doc.exists, true);
      expect(doc.data()!['creatorId'], 'user1');
      expect(doc.data()!['participantIds'], contains('user1'));
    });

    test('registerForEvent adds user when available', () async {
      final id = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final status = await eventService.registerForEvent(id, 'user2');

      expect(status, EventRegistrationStatus.registered);

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      final data = doc.data()!;
      expect(List.from(data['participantIds']), contains('user2'));
    });

    test('registerForEvent adds to waitlist when full', () async {
      final id = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event (creator + 5 users)
      for (int i = 2; i <= 6; i++) {
        await eventService.registerForEvent(id, 'user$i');
      }

      // Try adding 7th user
      final status = await eventService.registerForEvent(id, 'user7');

      expect(status, EventRegistrationStatus.waitlist);

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      final data = doc.data()!;
      expect(List.from(data['participantIds']), isNot(contains('user7')));
      expect(List.from(data['waitlist']), contains('user7'));
    });

    test('unregisterFromEvent removes user', () async {
       final id = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await eventService.registerForEvent(id, 'user2');

      await eventService.unregisterFromEvent(id, 'user2');

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      expect(List.from(doc.data()!['participantIds']), isNot(contains('user2')));
    });

    test('unregisterFromEvent promotes waitlist user', () async {
      final id = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event
      for (int i = 2; i <= 6; i++) {
        await eventService.registerForEvent(id, 'user$i');
      }

      // Add waitlist
      await eventService.registerForEvent(id, 'waitlist1');

      // User2 leaves
      await eventService.unregisterFromEvent(id, 'user2');

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      final data = doc.data()!;

      // User2 gone
      expect(List.from(data['participantIds']), isNot(contains('user2')));
      // waitlist1 promoted
      expect(List.from(data['participantIds']), contains('waitlist1'));
      expect(List.from(data['waitlist']), isEmpty);
      expect(data['participantStatus']['waitlist1'], 'confirmed');
    });

    test('unregisterFromEvent fails if < 24h', () async {
      final id = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(hours: 23)), // Within 24h
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      expect(
        () => eventService.unregisterFromEvent(id, 'user1'),
        throwsException
      );
    });

    test('registerForEvent fails if time conflict', () async {
      final time = DateTime.now().add(const Duration(days: 3));

      // Event 1
      final id1 = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: time,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Event 2 (Same time)
      final id2 = await eventService.createEvent(
        creatorId: 'user2', // different creator, but user1 will try to join
        dateTime: time,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // User1 tries to join Event 2
      expect(
        () => eventService.registerForEvent(id2, 'user1'),
        throwsException
      );
    });
  });
}

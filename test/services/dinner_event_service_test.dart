import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService dinnerEventService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dinnerEventService = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService', () {
    test('createEvent creates an event with correct data', () async {
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['creatorId'], 'user1');
      expect(data['status'], 'pending');
      expect((data['participantIds'] as List).length, 1);
    });

    test('joinEvent adds user to participants if not full', () async {
      // Create event with 1 user
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await dinnerEventService.joinEvent(eventId, 'user2');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final data = doc.data()!;
      final participants = List<String>.from(data['participantIds']);

      expect(participants.contains('user2'), true);
      expect(participants.length, 2);
    });

    test('joinEvent adds user to waitlist if full', () async {
      // Create event
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill up to 6 users
      for (int i = 2; i <= 6; i++) {
        await dinnerEventService.joinEvent(eventId, 'user$i');
      }

      // Try to join as 7th user
      await dinnerEventService.joinEvent(eventId, 'user7');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final data = doc.data()!;
      final participants = List<String>.from(data['participantIds']);
      final waitlist = List<String>.from(data['waitlist']);

      expect(participants.length, 6);
      expect(participants.contains('user7'), false);
      expect(waitlist.contains('user7'), true);
      expect(waitlist.length, 1);
    });

    test('leaveEvent removes user and promotes from waitlist', () async {
      // Create event
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill up to 6 users
      for (int i = 2; i <= 6; i++) {
        await dinnerEventService.joinEvent(eventId, 'user$i');
      }

      // Add user7 to waitlist
      await dinnerEventService.joinEvent(eventId, 'user7');

      // user1 leaves
      await dinnerEventService.leaveEvent(eventId, 'user1');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final data = doc.data()!;
      final participants = List<String>.from(data['participantIds']);
      final waitlist = List<String>.from(data['waitlist']);
      final participantStatus = Map<String, dynamic>.from(data['participantStatus']);

      expect(participants.contains('user1'), false);
      expect(participants.contains('user7'), true); // user7 promoted
      expect(participantStatus['user7'], 'confirmed');
      expect(participants.length, 6);
      expect(waitlist.isEmpty, true);
    });

    test('leaveEvent from waitlist just removes user', () async {
      // Create event and fill
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );
      for (int i = 2; i <= 6; i++) {
        await dinnerEventService.joinEvent(eventId, 'user$i');
      }

      // Add user7 to waitlist
      await dinnerEventService.joinEvent(eventId, 'user7');

      // user7 leaves
      await dinnerEventService.leaveEvent(eventId, 'user7');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final data = doc.data()!;
      final waitlist = List<String>.from(data['waitlist']);
      final participants = List<String>.from(data['participantIds']);

      expect(waitlist.contains('user7'), false);
      expect(participants.length, 6);
    });
  });
}

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
    test('createEvent creates a new event', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['creatorId'], 'user1');
      expect(data['status'], 'pending');
      expect(data['participantIds'], contains('user1'));
    });

    test('joinEvent adds user to participants if open', () async {
      // Create event
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.joinEvent(eventId, 'user2');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final participantIds = List<String>.from(doc.data()!['participantIds']);
      expect(participantIds.length, 2);
      expect(participantIds, contains('user2'));
    });

    test('joinEvent adds user to waitlist if full', () async {
      // Create event
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event (user1 + 5 others)
      for (int i = 2; i <= 6; i++) {
        await service.joinEvent(eventId, 'user$i');
      }

      // Verify full
      var doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect((doc.data()!['participantIds'] as List).length, 6);
      expect(doc.data()!['status'], 'confirmed');

      // Join 7th user
      await service.joinEvent(eventId, 'user7');

      doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final waitingListIds = List<String>.from(doc.data()!['waitingListIds']);
      expect(waitingListIds.length, 1);
      expect(waitingListIds, contains('user7'));
    });

    test('joinEvent throws if deadline passed', () async {
       // Create event with deadline in past
       final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(hours: 10)), // Event in 10h, deadline was 14h ago
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      expect(
        () => service.joinEvent(eventId, 'user2'),
        throwsException,
      );
    });

    test('leaveEvent promotes waitlisted user', () async {
      // Setup full event + 1 waitlist
       final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );
      for (int i = 2; i <= 6; i++) {
        await service.joinEvent(eventId, 'user$i');
      }
      await service.joinEvent(eventId, 'waituser');

      // user2 leaves
      await service.leaveEvent(eventId, 'user2');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final participantIds = List<String>.from(doc.data()!['participantIds']);
      final waitingListIds = List<String>.from(doc.data()!['waitingListIds']);

      expect(participantIds.length, 6); // Still full
      expect(participantIds, contains('waituser')); // Promoted
      expect(participantIds, isNot(contains('user2'))); // Removed
      expect(waitingListIds, isEmpty);
    });
  });
}

import 'package:chingu/services/dinner_event_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late DinnerEventService service;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService', () {
    test('createEvent creates a new event with correct data', () async {
      final creatorId = 'user_1';
      final dateTime = DateTime.now().add(const Duration(days: 1));

      final eventId = await service.createEvent(
        creatorId: creatorId,
        dateTime: dateTime,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        notes: 'Test event',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['creatorId'], creatorId);
      expect(data['participantIds'], [creatorId]);
      expect(data['status'], 'pending');
    });

    test('joinEvent adds user to participants if not full', () async {
      final creatorId = 'user_1';
      final eventId = await service.createEvent(
        creatorId: creatorId,
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final joinerId = 'user_2';
      await service.joinEvent(eventId, joinerId);

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final participantIds = List<String>.from(doc.data()!['participantIds']);
      expect(participantIds, contains(joinerId));
      expect(participantIds.length, 2);
    });

    test('joinEvent adds user to waitlist if full', () async {
      final creatorId = 'user_1';
      final eventId = await service.createEvent(
        creatorId: creatorId,
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2, // Set small limit for testing
      );

      // Add user 2 (fills the event)
      await service.joinEvent(eventId, 'user_2');

      // Try to add user 3
      final waiterId = 'user_3';
      await service.joinEvent(eventId, waiterId);

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final participantIds = List<String>.from(doc.data()!['participantIds']);
      final waitingListIds = List<String>.from(doc.data()!['waitingListIds']);

      expect(participantIds.length, 2);
      expect(participantIds, isNot(contains(waiterId)));
      expect(waitingListIds, contains(waiterId));
      expect(waitingListIds.length, 1);
    });

    test('leaveEvent promotes user from waitlist', () async {
      final creatorId = 'user_1';
      final eventId = await service.createEvent(
        creatorId: creatorId,
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2,
      );

      // Fill event
      await service.joinEvent(eventId, 'user_2'); // Now full

      // Add to waitlist
      final waiterId = 'user_3';
      await service.joinEvent(eventId, waiterId);

      // User 2 leaves
      await service.leaveEvent(eventId, 'user_2');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final participantIds = List<String>.from(doc.data()!['participantIds']);
      final waitingListIds = List<String>.from(doc.data()!['waitingListIds']);

      // Check user 2 is gone
      expect(participantIds, isNot(contains('user_2')));

      // Check user 3 promoted
      expect(participantIds, contains(waiterId));
      expect(participantIds.length, 2);
      expect(waitingListIds, isEmpty);
    });

    test('leaveEvent returns to pending status if participants drop too low', () async {
       final creatorId = 'user_1';
       final eventId = await service.createEvent(
        creatorId: creatorId,
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 3,
      );

      // Fill to confirm
      await service.joinEvent(eventId, 'user_2');
      await service.joinEvent(eventId, 'user_3');

      // Force status to confirmed (service does this automatically when full, let's verify)
      var doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(doc.data()!['status'], 'confirmed');

      // User 3 leaves
      await service.leaveEvent(eventId, 'user_3');

      // Now 2 people (max 3). Logic says if < max-1 ( < 2), pending.
      // 2 is not < 2. So it should stay confirmed?
      // Let's check service logic: if (newParticipantIds.length < (event.maxParticipants - 1))
      // 2 < (3-1=2) => False. So stays confirmed.

      // Let's make user 2 leave. Now 1 person. 1 < 2 => True. Should go pending.
      await service.leaveEvent(eventId, 'user_2');

      doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(doc.data()!['status'], 'pending');
    });
  });
}

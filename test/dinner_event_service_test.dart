import 'package:chingu/models/dinner_event_model.dart';
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
    test('registerForEvent joins successfully when space available', () async {
      final eventRef = await fakeFirestore.collection('dinner_events').add({
        'creatorId': 'host',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        'maxParticipants': 2,
        'participantIds': ['host'],
        'waitingListIds': [],
        'participantStatus': {'host': 'confirmed'},
        'status': 'pending',
        'city': 'Taipei',
        'district': 'Xinyi',
        'budgetRange': 1,
        'createdAt': Timestamp.now(),
      });

      final status = await service.registerForEvent(eventRef.id, 'user1');

      expect(status, EventRegistrationStatus.registered);

      final doc = await eventRef.get();
      final data = doc.data()!;
      expect(data['participantIds'], contains('user1'));
      expect(data['participantStatus']['user1'], 'confirmed');
      expect(data['status'], 'confirmed'); // 2/2 full -> confirmed
    });

    test('registerForEvent joins waitlist when full', () async {
      final eventRef = await fakeFirestore.collection('dinner_events').add({
        'creatorId': 'host',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        'maxParticipants': 1, // Only 1 allowed
        'participantIds': ['host'], // Full
        'waitingListIds': [],
        'participantStatus': {'host': 'confirmed'},
        'status': 'confirmed',
        'city': 'Taipei',
        'district': 'Xinyi',
        'budgetRange': 1,
        'createdAt': Timestamp.now(),
      });

      final status = await service.registerForEvent(eventRef.id, 'user1');

      expect(status, EventRegistrationStatus.waitlist);

      final doc = await eventRef.get();
      final data = doc.data()!;
      expect(data['participantIds'], isNot(contains('user1')));
      expect(data['waitingListIds'], contains('user1'));
    });

    test('registerForEvent throws when time conflict exists', () async {
      final now = DateTime.now();
      final eventTime = now.add(const Duration(days: 3));

      // User already in an event at this time
      await fakeFirestore.collection('dinner_events').add({
        'creatorId': 'other',
        'dateTime': Timestamp.fromDate(eventTime),
        'participantIds': ['user1'],
        'status': 'confirmed',
        'city': 'Taipei',
        'district': 'Xinyi',
        'budgetRange': 1,
        'createdAt': Timestamp.now(),
      });

      // Target event at same time
      final targetEventRef = await fakeFirestore.collection('dinner_events').add({
        'creatorId': 'host',
        'dateTime': Timestamp.fromDate(eventTime),
        'maxParticipants': 6,
        'participantIds': ['host'],
        'waitingListIds': [],
        'participantStatus': {'host': 'confirmed'},
        'status': 'pending',
        'city': 'Taipei',
        'district': 'Xinyi',
        'budgetRange': 1,
        'createdAt': Timestamp.now(),
      });

      expect(
        () => service.registerForEvent(targetEventRef.id, 'user1'),
        throwsException,
      );
    });

    test('unregisterFromEvent removes user successfully', () async {
      final eventRef = await fakeFirestore.collection('dinner_events').add({
        'creatorId': 'host',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        'maxParticipants': 6,
        'participantIds': ['host', 'user1'],
        'waitingListIds': [],
        'participantStatus': {'host': 'confirmed', 'user1': 'confirmed'},
        'status': 'pending',
        'city': 'Taipei',
        'district': 'Xinyi',
        'budgetRange': 1,
        'createdAt': Timestamp.now(),
      });

      await service.unregisterFromEvent(eventRef.id, 'user1');

      final doc = await eventRef.get();
      final data = doc.data()!;
      expect(data['participantIds'], isNot(contains('user1')));
    });

    test('unregisterFromEvent promotes waitlist user', () async {
      final eventRef = await fakeFirestore.collection('dinner_events').add({
        'creatorId': 'host',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        'maxParticipants': 2,
        'participantIds': ['host', 'user1'], // Full
        'waitingListIds': ['waiter1'],
        'participantStatus': {'host': 'confirmed', 'user1': 'confirmed'},
        'status': 'confirmed',
        'city': 'Taipei',
        'district': 'Xinyi',
        'budgetRange': 1,
        'createdAt': Timestamp.now(),
      });

      await service.unregisterFromEvent(eventRef.id, 'user1');

      final doc = await eventRef.get();
      final data = doc.data()!;
      expect(data['participantIds'], isNot(contains('user1')));
      expect(data['participantIds'], contains('waiter1')); // Promoted
      expect(data['waitingListIds'], isEmpty);
      expect(data['participantStatus']['waiter1'], 'confirmed');
    });

    test('unregisterFromEvent throws if within 24h deadline', () async {
      final eventRef = await fakeFirestore.collection('dinner_events').add({
        'creatorId': 'host',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 12))), // 12h from now
        'participantIds': ['host', 'user1'],
        'status': 'confirmed',
        'city': 'Taipei',
        'district': 'Xinyi',
        'budgetRange': 1,
        'createdAt': Timestamp.now(),
      });

      expect(
        () => service.unregisterFromEvent(eventRef.id, 'user1'),
        throwsException,
      );
    });
  });
}

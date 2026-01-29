import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DinnerEventService service;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService', () {
    test('joinEvent throws EventFullException when event is full', () async {
      final eventId = 'full_event';
      await fakeFirestore.collection('dinner_events').doc(eventId).set({
        'creatorId': 'user1',
        'dateTime': DateTime.now().add(const Duration(days: 2)),
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
        'participantIds': ['user1', 'user2', 'user3', 'user4', 'user5', 'user6'],
        'participantStatus': {
          'user1': 'confirmed', 'user2': 'confirmed', 'user3': 'confirmed',
          'user4': 'confirmed', 'user5': 'confirmed', 'user6': 'confirmed'
        },
        'waitingListIds': [],
        'registrationDeadline': DateTime.now().add(const Duration(days: 1)),
        'status': 'pending',
        'createdAt': DateTime.now(),
      });

      expect(
        () => service.joinEvent(eventId, 'new_user'),
        throwsA(isA<EventFullException>()),
      );
    });

    test('joinEvent throws Exception when deadline passed', () async {
      final eventId = 'past_deadline_event';
      await fakeFirestore.collection('dinner_events').doc(eventId).set({
        'creatorId': 'user1',
        'dateTime': DateTime.now().add(const Duration(days: 2)),
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
        'participantIds': ['user1'],
        'participantStatus': {'user1': 'confirmed'},
        'waitingListIds': [],
        'registrationDeadline': DateTime.now().subtract(const Duration(hours: 1)), // Passed
        'status': 'pending',
        'createdAt': DateTime.now(),
      });

      expect(
        () => service.joinEvent(eventId, 'new_user'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('報名已截止'))),
      );
    });

    test('joinWaitlist adds user to waitlist', () async {
      final eventId = 'waitlist_event';
      await fakeFirestore.collection('dinner_events').doc(eventId).set({
        'creatorId': 'user1',
        'dateTime': DateTime.now().add(const Duration(days: 2)),
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
        'participantIds': ['user1', 'user2', 'user3', 'user4', 'user5', 'user6'],
        'participantStatus': {},
        'waitingListIds': [],
        'registrationDeadline': DateTime.now().add(const Duration(days: 1)),
        'status': 'pending',
        'createdAt': DateTime.now(),
      });

      await service.joinWaitlist(eventId, 'waiter1');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final waitingListIds = List<String>.from(doc.data()!['waitingListIds']);
      expect(waitingListIds, contains('waiter1'));
    });

    test('leaveEvent promotes first user from waitlist', () async {
      final eventId = 'promote_event';
      await fakeFirestore.collection('dinner_events').doc(eventId).set({
        'creatorId': 'user1',
        'dateTime': DateTime.now().add(const Duration(days: 2)),
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
        'participantIds': ['user1', 'user2', 'user3', 'user4', 'user5', 'user6'],
        'participantStatus': {
          'user1': 'confirmed', 'user2': 'confirmed', 'user3': 'confirmed',
          'user4': 'confirmed', 'user5': 'confirmed', 'user6': 'confirmed'
        },
        'waitingListIds': ['waiter1', 'waiter2'],
        'registrationDeadline': DateTime.now().add(const Duration(days: 1)),
        'status': 'confirmed', // Event was full
        'createdAt': DateTime.now(),
      });

      // User1 leaves
      await service.leaveEvent(eventId, 'user1');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final data = doc.data()!;
      final participantIds = List<String>.from(data['participantIds']);
      final waitingListIds = List<String>.from(data['waitingListIds']);
      final status = data['status'];

      expect(participantIds, isNot(contains('user1')));
      expect(participantIds, contains('waiter1')); // Promoted
      expect(participantIds.length, 6); // Still full
      expect(waitingListIds, contains('waiter2'));
      expect(waitingListIds, isNot(contains('waiter1')));
      expect(status, DinnerEventStatus.confirmed.name); // Still confirmed
    });

    test('leaveEvent simply removes user if no waitlist', () async {
      final eventId = 'leave_event';
      await fakeFirestore.collection('dinner_events').doc(eventId).set({
        'creatorId': 'user1',
        'dateTime': DateTime.now().add(const Duration(days: 2)),
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
        'participantIds': ['user1', 'user2'],
        'participantStatus': {'user1': 'confirmed', 'user2': 'confirmed'},
        'waitingListIds': [],
        'registrationDeadline': DateTime.now().add(const Duration(days: 1)),
        'status': 'pending',
        'createdAt': DateTime.now(),
      });

      await service.leaveEvent(eventId, 'user2');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final participantIds = List<String>.from(doc.data()!['participantIds']);

      expect(participantIds, contains('user1'));
      expect(participantIds, isNot(contains('user2')));
      expect(participantIds.length, 1);
    });
  });
}

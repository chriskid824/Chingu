import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';
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

  group('DinnerEventService Registration', () {
    test('registerForEvent adds user to participants when not full', () async {
      // Create a dummy event
      final eventRef = fakeFirestore.collection('dinner_events').doc('event1');
      await eventRef.set({
        'creatorId': 'creator',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
        'maxParticipants': 6,
        'currentParticipants': 1,
        'participantIds': ['creator'],
        'waitlistIds': [],
        'participantStatus': {'creator': 'registered'},
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'icebreakerQuestions': [],
      });

      await service.registerForEvent('event1', 'user1');

      final snapshot = await eventRef.get();
      final data = snapshot.data()!;

      expect(data['participantIds'], contains('user1'));
      expect(data['currentParticipants'], 2);
      expect(data['participantStatus']['user1'], 'registered');
    });

    test('registerForEvent adds user to waitlist when full', () async {
      // Create a full event
      final eventRef = fakeFirestore.collection('dinner_events').doc('event_full');
      await eventRef.set({
        'creatorId': 'user1',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
        'maxParticipants': 2,
        'currentParticipants': 2,
        'participantIds': ['user1', 'user2'],
        'waitlistIds': [],
        'participantStatus': {'user1': 'registered', 'user2': 'registered'},
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'icebreakerQuestions': [],
      });

      await service.registerForEvent('event_full', 'user3');

      final snapshot = await eventRef.get();
      final data = snapshot.data()!;

      expect(data['participantIds'], isNot(contains('user3')));
      expect(data['waitlistIds'], contains('user3'));
      expect(data['currentParticipants'], 2); // Should stay same
      expect(data['participantStatus']['user3'], 'waitlist');
    });

    test('registerForEvent throws on time conflict', () async {
      final time = DateTime.now().add(const Duration(days: 2));

      // Existing event
      await fakeFirestore.collection('dinner_events').doc('existing_event').set({
        'creatorId': 'creator',
        'dateTime': Timestamp.fromDate(time),
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
        'maxParticipants': 6,
        'currentParticipants': 1,
        'participantIds': ['user1'],
        'waitlistIds': [],
        'participantStatus': {'user1': 'registered'},
        'status': 'confirmed',
        'createdAt': Timestamp.now(),
        'icebreakerQuestions': [],
      });

      // New event at same time
      await fakeFirestore.collection('dinner_events').doc('new_event').set({
        'creatorId': 'creator2',
        'dateTime': Timestamp.fromDate(time), // Same time
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Da-an',
        'maxParticipants': 6,
        'currentParticipants': 0,
        'participantIds': [],
        'waitlistIds': [],
        'participantStatus': {},
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'icebreakerQuestions': [],
      });

      expect(
        () => service.registerForEvent('new_event', 'user1'),
        throwsException,
      );
    });
  });

  group('DinnerEventService Unregistration', () {
    test('unregisterFromEvent promotes waitlist user', () async {
      final eventRef = fakeFirestore.collection('dinner_events').doc('event_waitlist');
      await eventRef.set({
        'creatorId': 'user1',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
        'maxParticipants': 2,
        'currentParticipants': 2,
        'participantIds': ['user1', 'user2'],
        'waitlistIds': ['user3'],
        'participantStatus': {
          'user1': 'registered',
          'user2': 'registered',
          'user3': 'waitlist'
        },
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'icebreakerQuestions': [],
      });

      // User 2 cancels
      await service.unregisterFromEvent('event_waitlist', 'user2');

      final snapshot = await eventRef.get();
      final data = snapshot.data()!;

      // User 2 should be cancelled/removed
      expect(data['participantIds'], isNot(contains('user2')));
      expect(data['participantStatus']['user2'], 'cancelled');

      // User 3 should be promoted
      expect(data['participantIds'], contains('user3'));
      expect(data['waitlistIds'], isNot(contains('user3')));
      expect(data['participantStatus']['user3'], 'registered');
      expect(data['currentParticipants'], 2); // 2 -> 1 (cancel) -> 2 (promote)
    });

    test('unregisterFromEvent throws if within 24h', () async {
      final eventRef = fakeFirestore.collection('dinner_events').doc('event_soon');
      await eventRef.set({
        'creatorId': 'user1',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 10))), // 10 hours from now
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
        'maxParticipants': 6,
        'currentParticipants': 1,
        'participantIds': ['user1'],
        'waitlistIds': [],
        'participantStatus': {'user1': 'registered'},
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'icebreakerQuestions': [],
      });

      expect(
        () => service.unregisterFromEvent('event_soon', 'user1'),
        throwsException,
      );
    });
  });
}

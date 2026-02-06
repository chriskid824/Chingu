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
    test('createEvent creates a pending event', () async {
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['status'], 'pending');
      expect(data['participantIds'], ['user1']);
      expect((data['waitlistIds'] as List).isEmpty, true);
    });

    test('joinEvent adds user to participants if spots available', () async {
      // Create event with 1 user
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await dinnerEventService.joinEvent(eventId, 'user2');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final data = doc.data()!;
      expect(data['participantIds'], contains('user2'));
      expect(data['participantStatus']['user2'], 'confirmed');
    });

    test('joinEvent adds user to waitlist if full (6 participants)', () async {
      // Create event
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Add 5 more users (Total 6)
      for (int i = 2; i <= 6; i++) {
        await dinnerEventService.joinEvent(eventId, 'user$i');
      }

      // Check it is full
      final docFull = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(docFull.data()!['status'], 'full');

      // Try adding 7th user
      await dinnerEventService.joinEvent(eventId, 'user7');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final data = doc.data()!;
      expect(data['participantIds'], hasLength(6));
      expect(data['waitlistIds'], contains('user7'));
      expect(data['status'], 'full'); // Should remain full
    });

    test('joinEvent throws exception if registration deadline passed', () async {
      // Manually create event with past deadline
      final eventId = 'past_event';
      await fakeFirestore.collection('dinner_events').doc(eventId).set({
        'creatorId': 'user1',
        'dateTime': DateTime.now().add(const Duration(hours: 1)), // Event soon
        'registrationDeadline': DateTime.now().subtract(const Duration(hours: 1)), // Deadline passed
        'participantIds': ['user1'],
        'waitlistIds': [],
        'participantStatus': {'user1': 'confirmed'},
        'status': 'pending',
        'createdAt': DateTime.now(),
        'budgetRange': 1,
        'city': 'Taipei',
        'district': 'Xinyi',
      });

      expect(
        () => dinnerEventService.joinEvent(eventId, 'user2'),
        throwsException,
      );
    });

    test('leaveEvent removes user and updates status from full to confirmed', () async {
      // Create event
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill it up to 6
      for (int i = 2; i <= 6; i++) {
        await dinnerEventService.joinEvent(eventId, 'user$i');
      }

      // Check full
      var doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(doc.data()!['status'], 'full');

      // User 6 leaves
      await dinnerEventService.leaveEvent(eventId, 'user6');

      doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(doc.data()!['participantIds'], isNot(contains('user6')));
      expect(doc.data()!['participantIds'], hasLength(5));
      expect(doc.data()!['status'], 'confirmed');
    });

    test('leaveEvent removes user from waitlist', () async {
      // Create event and fill it
      final eventId = await dinnerEventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );
      for (int i = 2; i <= 6; i++) {
        await dinnerEventService.joinEvent(eventId, 'user$i');
      }

      // User 7 joins waitlist
      await dinnerEventService.joinEvent(eventId, 'user7');

      // User 7 leaves
      await dinnerEventService.leaveEvent(eventId, 'user7');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(doc.data()!['waitlistIds'], isNot(contains('user7')));
    });
  });
}

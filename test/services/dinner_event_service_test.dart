import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService Tests', () {
    test('createEvent creates an event correctly', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      expect(doc.exists, true);
      expect(doc.data()!['creatorId'], 'user1');
      expect(doc.data()!['status'], 'pending');
    });

    test('joinEvent adds user to participants if not full', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 6,
      );

      await service.joinEvent(id, 'user2');

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      final participants = List<String>.from(doc.data()!['participantIds']);
      expect(participants.contains('user2'), true);
      expect(participants.length, 2); // user1 + user2
    });

    test('joinEvent adds user to waitlist if full', () async {
       // Create event with max 2
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2,
      );

      await service.joinEvent(id, 'user2'); // Full (2/2)

      // Try joining user3
      await service.joinEvent(id, 'user3');

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      final participants = List<String>.from(doc.data()!['participantIds']);
      final waitlist = List<String>.from(doc.data()!['waitlist']);

      expect(participants.contains('user3'), false);
      expect(waitlist.contains('user3'), true);
    });

    test('joinEvent throws if deadline passed', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        registrationDeadline: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(
        () async => await service.joinEvent(id, 'user2'),
        throwsException,
      );
    });

    test('leaveEvent promotes waiter', () async {
      // Create event with max 2, full (user1, user2), waitlist (user3)
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2,
      );
      await service.joinEvent(id, 'user2');
      await service.joinEvent(id, 'user3'); // Waitlist

      // User2 leaves
      await service.leaveEvent(id, 'user2');

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      final participants = List<String>.from(doc.data()!['participantIds']);
      final waitlist = List<String>.from(doc.data()!['waitlist']);
      final status = Map<String, String>.from(doc.data()!['participantStatus']);

      expect(participants.contains('user2'), false);
      expect(participants.contains('user3'), true); // Promoted
      expect(waitlist.isEmpty, true);
      expect(status['user3'], 'confirmed');
    });
  });
}

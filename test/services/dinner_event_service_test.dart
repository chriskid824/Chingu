import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_status.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService', () {
    test('createEvent creates an event with correct defaults', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['creatorId'], 'user1');
      expect(data['status'], 'pending');
      expect(data['maxParticipants'], 6);
      expect((data['participantIds'] as List).length, 1);
    });

    test('joinEvent adds user to participants when open', () async {
      // Create event
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.joinEvent(eventId, 'user2');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final participants = List<String>.from(doc.data()!['participantIds']);
      expect(participants.contains('user2'), true);
      expect(participants.length, 2);
    });

    test('joinEvent adds user to waitlist when full', () async {
      // Create event
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event (user1 already there, add 5 more)
      for (int i = 2; i <= 6; i++) {
        await service.joinEvent(eventId, 'user$i');
      }

      // Check status is full/confirmed
      var doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      expect(List<String>.from(doc.data()!['participantIds']).length, 6);

      // Attempt to join as user7
      await service.joinEvent(eventId, 'user7');

      doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final waitlist = List<String>.from(doc.data()!['waitlist']);
      expect(waitlist.contains('user7'), true);
      expect(List<String>.from(doc.data()!['participantIds']).contains('user7'), false);
    });

    test('joinEvent throws if deadline passed', () async {
        final deadline = DateTime.now().subtract(const Duration(hours: 1));

        final docRef = await fakeFirestore.collection('dinner_events').add({
            'participantIds': [],
            'waitlist': [],
            'maxParticipants': 6,
            'status': 'pending',
            'registrationDeadline': deadline,
            'creatorId': 'creator',
        });

        expect(
            () => service.joinEvent(docRef.id, 'user1'),
            throwsException
        );
    });

    test('leaveEvent removes user', () async {
      final eventId = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.joinEvent(eventId, 'user2');
      await service.leaveEvent(eventId, 'user2');

      final doc = await fakeFirestore.collection('dinner_events').doc(eventId).get();
      final participants = List<String>.from(doc.data()!['participantIds']);
      expect(participants.contains('user2'), false);
    });
  });
}

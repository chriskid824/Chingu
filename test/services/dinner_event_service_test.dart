import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService eventService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    eventService = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService Tests', () {
    test('createEvent creates an event correctly', () async {
      final id = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 4,
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['creatorId'], 'user1');
      expect(data['maxParticipants'], 4);
      expect(data['status'], 'pending');
    });

    test('joinEvent adds user to participants if not full', () async {
      // Create event with capacity 2
      final id = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2,
      );

      await eventService.joinEvent(id, 'user2');

      final event = await eventService.getEvent(id);
      expect(event!.participantIds, contains('user2'));
      expect(event.participantStatus['user2'], 'confirmed');
      expect(event.status, EventStatus.full); // 2 users (user1 + user2) = full
    });

    test('joinEvent adds user to waitlist if full', () async {
      // Create event with capacity 1
      final id = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 1,
      );

      // Event is full (user1 is creator)
      final eventBefore = await eventService.getEvent(id);
      expect(eventBefore!.isFull, true);

      await eventService.joinEvent(id, 'user2');

      final eventAfter = await eventService.getEvent(id);
      expect(eventAfter!.participantIds, isNot(contains('user2')));
      expect(eventAfter.waitingList, contains('user2'));
      expect(eventAfter.status, EventStatus.full);
    });

    test('joinEvent throws exception if deadline passed', () async {
      final id = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        registrationDeadline: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(
        () => eventService.joinEvent(id, 'user2'),
        throwsException,
      );
    });

    test('leaveEvent removes user', () async {
      final id = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2,
      );

      await eventService.joinEvent(id, 'user2');
      await eventService.leaveEvent(id, 'user2');

      final event = await eventService.getEvent(id);
      expect(event!.participantIds, isNot(contains('user2')));
    });

    test('leaveEvent promotes user from waitlist', () async {
      final id = await eventService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 1,
      );

      // user2 joins waitlist
      await eventService.joinEvent(id, 'user2');

      var event = await eventService.getEvent(id);
      expect(event!.waitingList, contains('user2'));

      // user1 (creator) leaves
      await eventService.leaveEvent(id, 'user1');

      event = await eventService.getEvent(id);
      expect(event!.participantIds, isNot(contains('user1')));
      expect(event.participantIds, contains('user2')); // Promoted
      expect(event.waitingList, isEmpty);
      expect(event.participantStatus['user2'], 'confirmed');
    });
  });
}

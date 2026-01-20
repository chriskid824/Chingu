import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';

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
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['creatorId'], 'user1');
      expect(data['maxParticipants'], 6);
      expect(data['currentParticipants'], 1);
      expect(data['participantIds'], ['user1']);
      expect(data['status'], 'pending');
    });

    test('registerForEvent adds user to participants when not full', () async {
      // Create event
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Register user2
      final status = await service.registerForEvent(id, 'user2');

      expect(status, EventRegistrationStatus.registered);

      final event = await service.getEvent(id);
      expect(event!.participantIds, contains('user2'));
      expect(event.currentParticipants, 2);
    });

    test('registerForEvent adds user to waitlist when full', () async {
      // Create event and fill it (5 more people + creator = 6)
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Add 5 users
      for (int i = 2; i <= 6; i++) {
        await service.registerForEvent(id, 'user$i');
      }

      final fullEvent = await service.getEvent(id);
      expect(fullEvent!.currentParticipants, 6);
      expect(fullEvent.isFull, true);

      // Register user7 (should go to waitlist)
      final status = await service.registerForEvent(id, 'user7');

      expect(status, EventRegistrationStatus.waitlist);

      final event = await service.getEvent(id);
      expect(event!.waitingList, contains('user7'));
      expect(event.participantIds, isNot(contains('user7')));
      expect(event.currentParticipants, 6);
    });

    test('unregisterFromEvent promotes user from waitlist', () async {
      // Create event and fill it + 1 waitlist
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      for (int i = 2; i <= 6; i++) {
        await service.registerForEvent(id, 'user$i');
      }
      await service.registerForEvent(id, 'wait_user');

      // Check waitlist
      var event = await service.getEvent(id);
      expect(event!.waitingList, contains('wait_user'));

      // user2 leaves
      await service.unregisterFromEvent(id, 'user2');

      // Check promotion
      event = await service.getEvent(id);
      expect(event!.participantIds, isNot(contains('user2')));
      expect(event.participantIds, contains('wait_user')); // Promoted
      expect(event.waitingList, isEmpty);
      expect(event.currentParticipants, 6);
    });

    test('getUserEvents returns waitlisted events', () async {
       // Create event and add user to waitlist
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      for (int i = 2; i <= 6; i++) {
        await service.registerForEvent(id, 'user$i');
      }
      await service.registerForEvent(id, 'me');

      final events = await service.getUserEvents('me');
      expect(events.length, 1);
      expect(events.first.id, id);
      expect(events.first.waitingList, contains('me'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService Registration', () {
    test('registerForEvent adds user to participants when not full', () async {
      // 1. Create Event
      final eventId = await service.createEvent(
        creatorId: 'creator_1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // 2. Register new user
      final status = await service.registerForEvent(eventId, 'user_2');

      // 3. Verify
      expect(status, EventRegistrationStatus.registered);

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, contains('user_2'));
      expect(event.currentParticipants, 2); // creator + user_2
    });

    test('registerForEvent adds user to waitlist when full', () async {
      // 1. Create Event
      final eventId = await service.createEvent(
        creatorId: 'user_1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // 2. Fill up the event (already has 1, add 5 more)
      for (int i = 2; i <= 6; i++) {
        await service.registerForEvent(eventId, 'user_$i');
      }

      var event = await service.getEvent(eventId);
      expect(event!.participantIds.length, 6);
      expect(event.isFull, true);

      // 3. Register 7th user
      final status = await service.registerForEvent(eventId, 'user_7');

      // 4. Verify
      expect(status, EventRegistrationStatus.waitlist);

      event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user_7')));
      expect(event.waitlist, contains('user_7'));
    });

    test('registerForEvent detects time conflict', () async {
      final now = DateTime.now().add(const Duration(days: 3));

      // Event A
      final eventA = await service.createEvent(
        creatorId: 'user_1',
        dateTime: now,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Event B (Same time)
      final eventB = await service.createEvent(
        creatorId: 'user_2', // user_1 is not creator
        dateTime: now,
        budgetRange: 1,
        city: 'Taipei',
        district: 'Da-an',
      );

      // User joins A
      // (Creator automatically joins, so user_1 is already in A)

      // User tries to join B
      expect(
        () async => await service.registerForEvent(eventB, 'user_1'),
        throwsException,
      );
    });
  });

  group('DinnerEventService Unregister', () {
    test('unregisterFromEvent removes user successfully', () async {
      final eventId = await service.createEvent(
        creatorId: 'user_1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.registerForEvent(eventId, 'user_2');

      await service.unregisterFromEvent(eventId, 'user_2');

      final event = await service.getEvent(eventId);
      expect(event!.participantIds, isNot(contains('user_2')));
      expect(event.currentParticipants, 1);
    });

    test('unregisterFromEvent promotes waitlist user', () async {
      final eventId = await service.createEvent(
        creatorId: 'user_1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill to 6
      for (int i = 2; i <= 6; i++) {
        await service.registerForEvent(eventId, 'user_$i');
      }
      // Add user_7 to waitlist
      await service.registerForEvent(eventId, 'user_7');

      // User 2 leaves
      await service.unregisterFromEvent(eventId, 'user_2');

      final event = await service.getEvent(eventId);

      // Verify User 2 is gone
      expect(event!.participantIds, isNot(contains('user_2')));

      // Verify User 7 is promoted
      expect(event.participantIds, contains('user_7'));
      expect(event.waitlist, isEmpty);
      expect(event.currentParticipants, 6);

      // Verify Notification created for user_7
      final notifications = await fakeFirestore
          .collection('users')
          .doc('user_7')
          .collection('notifications')
          .get();

      expect(notifications.docs.isNotEmpty, true);
      expect(notifications.docs.first.data()['title'], '候補成功！');
    });

    test('unregisterFromEvent throws if within 24 hours', () async {
      final eventId = await service.createEvent(
        creatorId: 'user_1',
        dateTime: DateTime.now().add(const Duration(hours: 23)), // < 24h
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      expect(
        () async => await service.unregisterFromEvent(eventId, 'user_1'),
        throwsException,
      );
    });
  });
}

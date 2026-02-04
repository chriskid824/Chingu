import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late DinnerEventService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: firestore);
  });

  group('DinnerEventService', () {
    test('createEvent creates an event correctly', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final event = await service.getEvent(id);
      expect(event, isNotNull);
      expect(event!.creatorId, 'user1');
      expect(event.participantIds, ['user1']);
      expect(event.participantStatus['user1'], 'confirmed');
    });

    test('joinEvent adds user to participants if not full', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.joinEvent(id, 'user2');

      final event = await service.getEvent(id);
      expect(event!.participantIds, contains('user2'));
      expect(event.participantStatus['user2'], 'confirmed');
    });

    test('joinEvent adds user to waitlist if full', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill up to 6 users (user1 is already there)
      for (var i = 2; i <= 6; i++) {
        await service.joinEvent(id, 'user$i');
      }

      final eventFull = await service.getEvent(id);
      expect(eventFull!.participantIds.length, 6);
      expect(eventFull.status, 'confirmed');

      // Add 7th user
      await service.joinEvent(id, 'user7');

      final eventWaitlist = await service.getEvent(id);
      expect(eventWaitlist!.participantIds.length, 6);
      expect(eventWaitlist.waitlist, contains('user7'));
      expect(eventWaitlist.participantStatus['user7'], 'waitlist');
    });

    test('leaveEvent promotes user from waitlist', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill up to 6
      for (var i = 2; i <= 6; i++) {
        await service.joinEvent(id, 'user$i');
      }
      // Add to waitlist
      await service.joinEvent(id, 'user7');
      await service.joinEvent(id, 'user8');

      // user1 leaves
      await service.leaveEvent(id, 'user1');

      final event = await service.getEvent(id);

      // Check user1 removed
      expect(event!.participantIds, isNot(contains('user1')));

      // Check user7 promoted
      expect(event.participantIds, contains('user7'));
      expect(event.participantStatus['user7'], 'confirmed');
      expect(event.waitlist, isNot(contains('user7')));

      // Check user8 still in waitlist
      expect(event.waitlist, contains('user8'));

      // Check participant count is still 6
      expect(event.participantIds.length, 6);
    });

    test('leaveEvent just removes if no waitlist', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.joinEvent(id, 'user2');
      await service.leaveEvent(id, 'user2');

      final event = await service.getEvent(id);
      expect(event!.participantIds, isNot(contains('user2')));
      expect(event.participantIds.length, 1);
    });

    test('cannot join if deadline passed', () async {
       // Create event with deadline passed (now is after (dateTime - 24h))
       // If event is now, deadline was 24h ago.

       final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now(),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      expect(
        () => service.joinEvent(id, 'user2'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('報名已截止'))),
      );
    });
  });
}

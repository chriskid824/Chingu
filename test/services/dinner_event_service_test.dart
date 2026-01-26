import 'package:chingu/enums/event_status.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: fakeFirestore);
  });

  group('DinnerEventService', () {
    test('createEvent creates a new event with open status', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      final event = DinnerEventModel.fromMap(doc.data()!, doc.id);

      expect(event.creatorId, 'user1');
      expect(event.status, EventStatus.open);
      expect(event.participantIds, ['user1']);
      expect(event.registrationDeadline, isNotNull);
    });

    test('joinEvent adds user to participants if open', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.joinEvent(id, 'user2');

      final event = await service.getEvent(id);
      expect(event!.participantIds, contains('user2'));
      expect(event.participantIds.length, 2);
    });

    test('joinEvent adds user to waitlist if full', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill up the event (user1 is already in)
      for (var i = 2; i <= 6; i++) {
        await service.joinEvent(id, 'user$i');
      }

      var event = await service.getEvent(id);
      expect(event!.status, EventStatus.full);
      expect(event.participantIds.length, 6);

      // Join as 7th user
      await service.joinEvent(id, 'user7');

      event = await service.getEvent(id);
      expect(event!.waitlistIds, contains('user7'));
      expect(event.participantIds, isNot(contains('user7')));
    });

    test('joinEvent throws if deadline passed', () async {
      final docRef = fakeFirestore.collection('dinner_events').doc();
      final event = DinnerEventModel(
        id: docRef.id,
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(hours: 1)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        participantIds: ['user1'],
        participantStatus: {},
        registrationDeadline: DateTime.now().subtract(const Duration(hours: 1)), // Passed
        status: EventStatus.open,
        createdAt: DateTime.now(),
      );
      await docRef.set(event.toMap());

      expect(
        () => service.joinEvent(docRef.id, 'user2'),
        throwsA(isA<Exception>()),
      );
    });

    test('leaveEvent promotes from waitlist', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 7)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill + Waitlist
      for (var i = 2; i <= 6; i++) {
        await service.joinEvent(id, 'user$i');
      }
      await service.joinEvent(id, 'user7');

      var event = await service.getEvent(id);
      expect(event!.waitlistIds, ['user7']);

      // user1 leaves
      await service.leaveEvent(id, 'user1');

      event = await service.getEvent(id);
      expect(event!.participantIds, isNot(contains('user1')));
      expect(event.participantIds, contains('user7')); // user7 promoted
      expect(event.waitlistIds, isEmpty);
      expect(event.status, EventStatus.full); // Still 6 people
    });
  });
}

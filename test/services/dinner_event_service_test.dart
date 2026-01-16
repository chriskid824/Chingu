import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';
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
    test('createEvent creates an event correctly', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['creatorId'], 'user1');
      expect(data['maxParticipants'], 6);
      expect(data['participantIds'], ['user1']);
      expect(data['participantStatus'], {'user1': 'confirmed'});
    });

    test('registerForEvent adds user when not full', () async {
      // Create event
      final id = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Register user
      final status = await service.registerForEvent(id, 'user2');

      expect(status, EventRegistrationStatus.registered);

      final event = await service.getEvent(id);
      expect(event!.participantIds, contains('user2'));
      expect(event.participantIds.length, 2);
    });

    test('registerForEvent adds to waitlist when full', () async {
      // Create event
      final id = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Fill event (creator is 1, add 5 more)
      for (int i = 0; i < 5; i++) {
        await service.registerForEvent(id, 'user_$i');
      }

      final fullEvent = await service.getEvent(id);
      expect(fullEvent!.participantIds.length, 6);

      // Register waitlist user
      final status = await service.registerForEvent(id, 'waitlist_user');

      expect(status, EventRegistrationStatus.waitlist);

      final event = await service.getEvent(id);
      expect(event!.participantIds, isNot(contains('waitlist_user')));
      expect(event.waitingListIds, contains('waitlist_user'));
    });

    test('unregisterFromEvent promotes waitlist user', () async {
      // Create event and fill it
      final id = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      for (int i = 0; i < 5; i++) {
        await service.registerForEvent(id, 'user_$i');
      }

      // Add waitlist user
      await service.registerForEvent(id, 'waitlist_user');

      var event = await service.getEvent(id);
      expect(event!.waitingListIds, contains('waitlist_user'));

      // Remove a participant
      await service.unregisterFromEvent(id, 'user_0');

      event = await service.getEvent(id);
      // user_0 removed
      expect(event!.participantIds, isNot(contains('user_0')));
      // waitlist_user promoted
      expect(event.participantIds, contains('waitlist_user'));
      expect(event.waitingListIds, isEmpty);
      expect(event.participantStatus['waitlist_user'], 'confirmed');
    });

    test('unregisterFromEvent fails within 24 hours', () async {
       // Create event near now
      final id = await service.createEvent(
        creatorId: 'creator',
        dateTime: DateTime.now().add(const Duration(hours: 20)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      // Attempt unregister
      expect(
        () => service.unregisterFromEvent(id, 'creator'),
        throwsException,
      );
    });
  });
}

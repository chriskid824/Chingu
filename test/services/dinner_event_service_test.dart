import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/event_status.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: fakeFirestore);
  });

  test('createEvent creates a pending event with correct deadline', () async {
    final now = DateTime.now();
    final eventDate = now.add(const Duration(days: 3));

    final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: eventDate,
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
    );

    final event = await service.getEvent(id);
    expect(event, isNotNull);
    expect(event!.status, EventStatus.pending);
    expect(event.participantIds, ['user1']);
    expect(event.participantIds.length, 1);

    // Check deadline is 24h before
    final diff = event.dateTime.difference(event.registrationDeadline).inHours;
    expect(diff, 24);
  });

  test('joinEvent adds user', () async {
    final eventDate = DateTime.now().add(const Duration(days: 3));
    final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: eventDate,
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
    );

    await service.joinEvent(id, 'user2');

    final event = await service.getEvent(id);
    expect(event!.participantIds, contains('user2'));
    expect(event.participantIds.length, 2);
  });

  test('joinEvent throws if full', () async {
    final eventDate = DateTime.now().add(const Duration(days: 3));
    final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: eventDate,
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
    );

    // Fill up to 6
    for (int i = 2; i <= 6; i++) {
      await service.joinEvent(id, 'user$i');
    }

    // Try to join as 7th
    expect(
      () => service.joinEvent(id, 'user7'),
      throwsException,
    );
  });

  test('Event becomes confirmed when full', () async {
    final eventDate = DateTime.now().add(const Duration(days: 3));
    final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: eventDate,
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
    );

    for (int i = 2; i <= 6; i++) {
      await service.joinEvent(id, 'user$i');
    }

    final event = await service.getEvent(id);
    expect(event!.status, EventStatus.confirmed);
  });

  test('joinWaitlist adds user to waitlist', () async {
    final eventDate = DateTime.now().add(const Duration(days: 3));
    final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: eventDate,
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
    );

    // Make it full
    for (int i = 2; i <= 6; i++) {
      await service.joinEvent(id, 'user$i');
    }

    await service.joinWaitlist(id, 'user7');

    final event = await service.getEvent(id);
    expect(event!.waitingList, contains('user7'));
  });

  test('leaveEvent promotes waitlisted user', () async {
    final eventDate = DateTime.now().add(const Duration(days: 3));
    final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: eventDate,
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
    );

    // Fill up
    for (int i = 2; i <= 6; i++) {
      await service.joinEvent(id, 'user$i');
    }
    // Add to waitlist
    await service.joinWaitlist(id, 'user7');

    // user1 leaves
    await service.leaveEvent(id, 'user1');

    final event = await service.getEvent(id);
    expect(event!.participantIds, isNot(contains('user1')));
    expect(event.participantIds, contains('user7')); // Promoted
    expect(event.waitingList, isEmpty);
    expect(event.participantIds.length, 6);
    expect(event.status, EventStatus.confirmed); // Still confirmed
  });
}

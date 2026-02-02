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

  test('createEvent creates a valid event', () async {
    final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: DateTime.now().add(const Duration(days: 2)),
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
    );

    final snapshot = await fakeFirestore.collection('dinner_events').doc(id).get();
    expect(snapshot.exists, true);
    final data = snapshot.data()!;
    expect(data['creatorId'], 'user1');
    expect(data['participantIds'], ['user1']);
    expect(data['status'], 'pending');
  });

  test('joinEvent adds to participants if not full', () async {
    // Create event with 1 user
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
    expect(event.waitlistIds, isEmpty);
  });

  test('joinEvent adds to waitlist if full', () async {
    // Create event
    final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: DateTime.now().add(const Duration(days: 2)),
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
    );

    // Fill to 6
    for (int i = 2; i <= 6; i++) {
      await service.joinEvent(id, 'user$i');
    }

    final fullEvent = await service.getEvent(id);
    expect(fullEvent!.participantIds.length, 6);
    expect(fullEvent.status, EventStatus.confirmed);

    // Try joining as 7th
    await service.joinEvent(id, 'user7');

    final updatedEvent = await service.getEvent(id);
    expect(updatedEvent!.participantIds.length, 6);
    expect(updatedEvent.waitlistIds, contains('user7'));
  });

  test('leaveEvent promotes from waitlist', () async {
     // Create event
    final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: DateTime.now().add(const Duration(days: 2)),
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
    );

    // Fill to 6
    for (int i = 2; i <= 6; i++) {
      await service.joinEvent(id, 'user$i');
    }

    // Add waiter
    await service.joinEvent(id, 'waiter1');

    // user1 leaves
    await service.leaveEvent(id, 'user1');

    final event = await service.getEvent(id);
    expect(event!.participantIds, isNot(contains('user1')));
    expect(event.participantIds, contains('waiter1'));
    expect(event.waitlistIds, isEmpty);
    expect(event.isUserConfirmed('waiter1'), true);
  });
}

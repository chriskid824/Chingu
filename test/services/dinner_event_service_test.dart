import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/event_status.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DinnerEventService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = DinnerEventService(firestore: fakeFirestore);
  });

  test('createEvent creates a document', () async {
    final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
    );

    final snapshot = await fakeFirestore.collection('dinner_events').doc(id).get();
    expect(snapshot.exists, true);
    expect(snapshot.data()!['creatorId'], 'user1');
    expect(snapshot.data()!['status'], EventStatus.pending.name);
  });

  test('joinEvent adds participant', () async {
    // Create event
    final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
    );

    await service.joinEvent(id, 'user2');

    final snapshot = await fakeFirestore.collection('dinner_events').doc(id).get();
    final participants = List<String>.from(snapshot.data()!['participantIds']);
    expect(participants.contains('user2'), true);
  });

  test('joinEvent throws if full', () async {
     final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
      maxParticipants: 2, // Limit to 2
    );

    await service.joinEvent(id, 'user2'); // 2/2 full

    expect(() => service.joinEvent(id, 'user3'), throwsException);
  });

  test('addToWaitlist adds to waitlist', () async {
     final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
      maxParticipants: 1, // Full
    );

    // user1 is already participant
    await service.addToWaitlist(id, 'user2');

    final snapshot = await fakeFirestore.collection('dinner_events').doc(id).get();
    final waitlist = List<String>.from(snapshot.data()!['waitlist']);
    expect(waitlist.contains('user2'), true);
  });

  test('leaveEvent triggers auto-promotion', () async {
     final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
      maxParticipants: 1,
    );

    // Full with user1
    // Add user2 to waitlist
    await service.addToWaitlist(id, 'user2');

    // user1 leaves
    await service.leaveEvent(id, 'user1');

    final snapshot = await fakeFirestore.collection('dinner_events').doc(id).get();
    final participants = List<String>.from(snapshot.data()!['participantIds']);
    final waitlist = List<String>.from(snapshot.data()!['waitlist']);

    expect(participants.contains('user2'), true); // Promoted
    expect(waitlist.isEmpty, true);
    expect(participants.contains('user1'), false);
  });

  test('joinEvent checks deadline', () async {
      final past = DateTime.now().subtract(const Duration(hours: 1));

      final id = await service.createEvent(
      creatorId: 'user1',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      budgetRange: 1,
      city: 'Taipei',
      district: 'Xinyi',
      registrationDeadline: past, // Deadline passed
    );

    expect(() => service.joinEvent(id, 'user2'), throwsException);
  });
}

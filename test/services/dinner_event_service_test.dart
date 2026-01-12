import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mocks
class MockDinnerEventService extends Mock implements DinnerEventService {}

void main() {
  late FakeFirebaseFirestore firestore;
  late DinnerEventService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    // We can't easily inject the fake instance into the real service because it instantiates internal Firestore.instance.
    // However, since we are testing logic, we might need to modify the service to accept an instance or use a wrapper.
    // For this test, since I cannot modify the Service constructor without potentially breaking other things (DI),
    // I will write integration-style tests assuming the Service uses FirebaseFirestore.instance
    // but in a unit test environment, we can't easily mock the singleton instance unless we use a wrapper.

    // BUT, `fake_cloud_firestore` doesn't automatically replace `FirebaseFirestore.instance`.
    // Let's rely on the fact that we modified the model logic which is pure Dart.
    // We will test the MODEL logic primarily for waitlist checks, and trust the Firestore transactions (which are hard to mock without DI).

    // Actually, I can test the Model methods.
  });

  group('DinnerEventModel Logic', () {
    test('isFull returns true when participants >= maxParticipants', () {
       final event = DinnerEventModel(
         id: '1',
         creatorId: 'creator',
         dateTime: DateTime.now().add(const Duration(days: 1)),
         budgetRange: 1,
         city: 'Taipei',
         district: 'Xinyi',
         maxParticipants: 2,
         participantIds: ['a', 'b'],
         participantStatus: {},
         waitingList: [],
         registrationDeadline: DateTime.now(),
         createdAt: DateTime.now(),
       );

       expect(event.isFull, isTrue);
    });

    test('isFull returns false when participants < maxParticipants', () {
       final event = DinnerEventModel(
         id: '1',
         creatorId: 'creator',
         dateTime: DateTime.now().add(const Duration(days: 1)),
         budgetRange: 1,
         city: 'Taipei',
         district: 'Xinyi',
         maxParticipants: 2,
         participantIds: ['a'],
         participantStatus: {},
         waitingList: [],
         registrationDeadline: DateTime.now(),
         createdAt: DateTime.now(),
       );

       expect(event.isFull, isFalse);
    });

    test('isRegistrationClosed returns correct boolean', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      final future = DateTime.now().add(const Duration(hours: 1));

      final closedEvent = DinnerEventModel(
         id: '1',
         creatorId: 'creator',
         dateTime: DateTime.now().add(const Duration(days: 1)),
         budgetRange: 1,
         city: 'Taipei',
         district: 'Xinyi',
         participantIds: [],
         participantStatus: {},
         waitingList: [],
         registrationDeadline: past,
         createdAt: DateTime.now(),
      );

      final openEvent = closedEvent.copyWith(registrationDeadline: future);

      expect(closedEvent.isRegistrationClosed, isTrue);
      expect(openEvent.isRegistrationClosed, isFalse);
    });
  });

  group('EventStatus Enum', () {
    test('String conversion works', () {
      expect(EventStatus.pending.toStringValue(), 'pending');
      expect(EventStatus.fromString('pending'), EventStatus.pending);
      expect(EventStatus.fromString('unknown'), EventStatus.pending); // default
      expect(EventStatus.fromString('confirmed'), EventStatus.confirmed);
    });
  });
}

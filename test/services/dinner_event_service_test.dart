import 'package:chingu/models/event_registration_status.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'dinner_event_service_test.mocks.dart';

@GenerateMocks([NotificationStorageService])
void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockNotificationStorageService mockNotificationService;
  late DinnerEventService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockNotificationService = MockNotificationStorageService();
    service = DinnerEventService(
      firestore: fakeFirestore,
      notificationService: mockNotificationService,
    );

    // Stub the void method to do nothing
    when(mockNotificationService.createEventNotification(
      eventId: anyNamed('eventId'),
      eventTitle: anyNamed('eventTitle'),
      message: anyNamed('message'),
      imageUrl: anyNamed('imageUrl'),
      userId: anyNamed('userId'),
    )).thenAnswer((_) async {});
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

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['creatorId'], 'user1');
      expect(data['participantIds'], ['user1']);
      expect(data['maxParticipants'], 6);
    });

    test('registerForEvent adds user when space available', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await service.registerForEvent(id, 'user2');

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      final data = doc.data()!;
      expect(data['participantIds'], contains('user2'));
      // EventRegistrationStatus.registered.toStringValue() -> 'registered'
      expect(data['participantStatus']['user2'], 'registered');
    });

    test('registerForEvent adds to waitlist when full', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2,
      );

      await service.registerForEvent(id, 'user2'); // 2/2 Full

      await service.registerForEvent(id, 'user3');

      final doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      final data = doc.data()!;

      expect(data['participantIds'], hasLength(2));
      expect(data['participantIds'], containsAll(['user1', 'user2']));
      expect(data['participantIds'], isNot(contains('user3')));

      expect(data['waitlist'], contains('user3'));
    });

    test('unregisterFromEvent promotes waitlist user', () async {
      final id = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 2,
      );
      await service.registerForEvent(id, 'user2');
      await service.registerForEvent(id, 'user3'); // waitlist

      var doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      expect(doc.data()!['waitlist'], ['user3']);

      await service.unregisterFromEvent(id, 'user1');

      doc = await fakeFirestore.collection('dinner_events').doc(id).get();
      final data = doc.data()!;

      expect(data['participantIds'], isNot(contains('user1')));
      expect(data['participantIds'], contains('user3'));
      expect(data['waitlist'], isEmpty);
      expect(data['participantStatus']['user3'], 'registered');

      verify(mockNotificationService.createEventNotification(
        userId: 'user3',
        eventId: id,
        eventTitle: anyNamed('eventTitle'),
        message: anyNamed('message'),
        imageUrl: anyNamed('imageUrl'),
      )).called(1);
    });

    test('getUserEvents filters by type', () async {
      final id1 = await service.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      ); // Registered

      final id2 = await service.createEvent(
        creatorId: 'user2',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
        maxParticipants: 1,
      );
      await service.registerForEvent(id2, 'user1'); // Waitlist (creator is user2, max 1)

      final allEvents = await service.getUserEvents('user1');
      expect(allEvents.length, 2);

      final waitlistEvents = await service.getUserEvents('user1', filterType: 'waitlist');
      expect(waitlistEvents.length, 1);
      expect(waitlistEvents.first.id, id2);
    });
  });
}

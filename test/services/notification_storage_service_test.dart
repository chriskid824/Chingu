import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/models/notification_model.dart';

@GenerateMocks([FirebaseAuth, User])
import 'notification_storage_service_test.mocks.dart';

void main() {
  late NotificationStorageService service;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Setup Auth mock
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test_user_id');

    // Setup Service
    service = NotificationStorageService();
    service.firestore = fakeFirestore;
    service.auth = mockAuth;
  });

  group('NotificationStorageService', () {
    final testNotification = NotificationModel(
      id: 'test_notification_id',
      userId: 'test_user_id',
      type: 'system',
      title: 'Test Title',
      message: 'Test Message',
      createdAt: DateTime.now(),
      isRead: false,
    );

    test('saveNotification should save to correct collection', () async {
      final id = await service.saveNotification(testNotification);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('notifications')
          .doc(id)
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()!['title'], 'Test Title');
      expect(snapshot.data()!['userId'], 'test_user_id');
    });

    test('getNotifications should retrieve notifications', () async {
      // Add a notification directly to firestore
      await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('notifications')
          .add(testNotification.toMap());

      final notifications = await service.getNotifications();

      expect(notifications.length, 1);
      expect(notifications.first.title, 'Test Title');
    });

    test('markAsRead should update isRead field', () async {
       final docRef = await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('notifications')
          .add(testNotification.toMap());

      await service.markAsRead(docRef.id);

      final snapshot = await docRef.get();
      expect(snapshot.data()!['isRead'], isTrue);
    });

    test('getUnreadCount should return correct count', () async {
       await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('notifications')
          .add(testNotification.toMap()); // isRead: false

       await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('notifications')
          .add(testNotification.markAsRead().toMap()); // isRead: true

       final count = await service.getUnreadCount();
       expect(count, 1);
    });
  });
}

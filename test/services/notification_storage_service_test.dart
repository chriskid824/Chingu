import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'notification_storage_service_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User])
void main() {
  late NotificationStorageService service;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Setup Mock User
    when(mockUser.uid).thenReturn('test_user_id');
    when(mockAuth.currentUser).thenReturn(mockUser);

    service = NotificationStorageService();
    service.setDependencies(firestore: fakeFirestore, auth: mockAuth);
  });

  tearDown(() {
    // Reset dependencies is not strictly necessary as setUp re-initializes,
    // but good practice if state leaked.
    // However, NotificationStorageService is a Singleton, so we MUST reset it.
    // But our setDependencies overwrites the private fields, so next setUp will overwrite them again.
  });

  group('NotificationStorageService', () {
    final notification = NotificationModel(
      id: 'notif_1',
      userId: 'test_user_id',
      type: 'system',
      title: 'Test Title',
      message: 'Test Message',
      createdAt: DateTime.now(),
    );

    test('saveNotification should add document to firestore', () async {
      final id = await service.saveNotification(notification);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('notifications')
          .doc(id)
          .get();

      expect(snapshot.exists, true);
      expect(snapshot.data()!['title'], 'Test Title');
    });

    test('getNotifications should return notifications', () async {
      // Add a notification first
      await service.saveNotification(notification);

      final notifications = await service.getNotifications();

      expect(notifications.length, 1);
      expect(notifications.first.title, 'Test Title');
    });

    test('markAsRead should update isRead field', () async {
      final id = await service.saveNotification(notification);

      await service.markAsRead(id);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('notifications')
          .doc(id)
          .get();

      expect(snapshot.data()!['isRead'], true);
    });

    test('getUnreadCount should return correct count', () async {
      await service.saveNotification(notification); // Unread
      await service.saveNotification(notification); // Unread

      // Create a read notification
      final readNotification = NotificationModel(
        id: 'notif_2',
        userId: 'test_user_id',
        type: 'system',
        title: 'Read Notif',
        message: 'Message',
        isRead: true,
        createdAt: DateTime.now(),
      );
      await service.saveNotification(readNotification);

      final count = await service.getUnreadCount();
      expect(count, 2);
    });
  });
}

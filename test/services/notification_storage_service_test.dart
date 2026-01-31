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
  group('NotificationStorageService', () {
    late NotificationStorageService service;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    final String userId = 'test_user_123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      service = NotificationStorageService();

      // Setup default user
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn(userId);

      // Inject dependencies
      service.setDependencies(firestore: fakeFirestore, auth: mockAuth);
    });

    test('saveNotification should store notification in Firestore', () async {
      final notification = NotificationModel(
        id: 'notif_1',
        userId: userId,
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        createdAt: DateTime.now(),
        isRead: false,
      );

      await service.saveNotification(notification);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['title'], 'Test Title');
    });

    test('getNotifications should retrieve notifications', () async {
      // Add some notifications
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'userId': userId,
        'type': 'system',
        'title': 'Notification 1',
        'message': 'Message 1',
        'createdAt': DateTime.now(),
        'isRead': false,
      });

      final notifications = await service.getNotifications();
      expect(notifications.length, 1);
      expect(notifications.first.title, 'Notification 1');
    });

    test('markAsRead should update isRead field', () async {
       final docRef = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'userId': userId,
        'type': 'system',
        'title': 'Notification 1',
        'message': 'Message 1',
        'createdAt': DateTime.now(),
        'isRead': false,
      });

      await service.markAsRead(docRef.id);

      final doc = await docRef.get();
      expect(doc.data()?['isRead'], true);
    });

    test('getUnreadCount should return correct count', () async {
       await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'userId': userId,
        'type': 'system',
        'title': 'Notification 1',
        'message': 'Message 1',
        'createdAt': DateTime.now(),
        'isRead': false,
      });

       await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'userId': userId,
        'type': 'system',
        'title': 'Notification 2',
        'message': 'Message 2',
        'createdAt': DateTime.now(),
        'isRead': true,
      });

      final count = await service.getUnreadCount();
      expect(count, 1);
    });
  });
}

import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late NotificationStorageService service;
  late FakeFirebaseFirestore fakeFirestore;
  final String testUserId = 'test_user_id';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = NotificationStorageService();
    service.firestore = fakeFirestore;
    service.testUserId = testUserId;
  });

  group('NotificationStorageService Tests', () {
    test('saveNotification should add notification to user subcollection', () async {
      final notification = NotificationModel(
        id: '',
        userId: testUserId,
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final id = await service.saveNotification(notification);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .doc(id)
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['title'], equals('Test Title'));
      expect(snapshot.data()?['userId'], equals(testUserId));
    });

    test('getNotifications should return notifications for user', () async {
      final notification = NotificationModel(
        id: '',
        userId: testUserId,
        type: 'system',
        title: 'Test Title 1',
        message: 'Test Message 1',
        isRead: false,
        createdAt: DateTime.now(),
      );

      await service.saveNotification(notification);

      final notifications = await service.getNotifications();
      expect(notifications.length, equals(1));
      expect(notifications.first.title, equals('Test Title 1'));
    });

    test('getUnreadCount should return correct count', () async {
      await service.saveNotification(NotificationModel(
        id: '',
        userId: testUserId,
        type: 'system',
        title: 'Unread 1',
        message: 'Msg',
        isRead: false,
        createdAt: DateTime.now(),
      ));

      await service.saveNotification(NotificationModel(
        id: '',
        userId: testUserId,
        type: 'system',
        title: 'Read 1',
        message: 'Msg',
        isRead: true,
        createdAt: DateTime.now(),
      ));

      final count = await service.getUnreadCount();
      expect(count, equals(1));
    });

    test('markAsRead should update isRead status', () async {
      final id = await service.saveNotification(NotificationModel(
        id: '',
        userId: testUserId,
        type: 'system',
        title: 'Unread',
        message: 'Msg',
        isRead: false,
        createdAt: DateTime.now(),
      ));

      await service.markAsRead(id);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .doc(id)
          .get();

      expect(snapshot.data()?['isRead'], isTrue);
    });

    test('markAllAsRead should update all unread notifications', () async {
      await service.saveNotification(NotificationModel(
        id: '',
        userId: testUserId,
        type: 'system',
        title: 'Unread 1',
        message: 'Msg',
        isRead: false,
        createdAt: DateTime.now(),
      ));

      await service.saveNotification(NotificationModel(
        id: '',
        userId: testUserId,
        type: 'system',
        title: 'Unread 2',
        message: 'Msg',
        isRead: false,
        createdAt: DateTime.now(),
      ));

      await service.markAllAsRead();

      final unreadCount = await service.getUnreadCount();
      expect(unreadCount, equals(0));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/models/notification_model.dart';

void main() {
  group('NotificationStorageService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late NotificationStorageService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = NotificationStorageService(firestore: fakeFirestore);
    });

    final testNotification = NotificationModel(
      id: 'test_id',
      userId: 'user_1',
      type: 'system',
      title: 'Test Notification',
      message: 'This is a test',
      createdAt: DateTime.now(),
    );

    test('saveNotification saves notification to firestore', () async {
      await service.saveNotification(testNotification);

      final snapshot = await fakeFirestore.collection('notifications').doc('test_id').get();
      expect(snapshot.exists, true);
      expect(snapshot.data()?['title'], 'Test Notification');
    });

    test('saveNotification generates id if empty', () async {
      final notificationWithoutId = NotificationModel(
        id: '',
        userId: 'user_1',
        type: 'system',
        title: 'No ID',
        message: 'Test',
        createdAt: DateTime.now(),
      );

      await service.saveNotification(notificationWithoutId);

      final snapshot = await fakeFirestore.collection('notifications').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['title'], 'No ID');
    });

    test('getNotificationsStream returns stream of notifications for user', () async {
      await service.saveNotification(testNotification);
      await service.saveNotification(NotificationModel(
        id: 'other_id',
        userId: 'user_2', // Different user
        type: 'system',
        title: 'Other User',
        message: 'Test',
        createdAt: DateTime.now(),
      ));

      final stream = service.getNotificationsStream('user_1');

      expect(stream, emits(predicate<List<NotificationModel>>((list) {
        return list.length == 1 && list.first.id == 'test_id';
      })));
    });

    test('markAsRead updates isRead field', () async {
      await service.saveNotification(testNotification); // Defaults to isRead: false

      await service.markAsRead('test_id');

      final snapshot = await fakeFirestore.collection('notifications').doc('test_id').get();
      expect(snapshot.data()?['isRead'], true);
    });

    test('markAllAsRead updates all unread notifications for user', () async {
      await service.saveNotification(testNotification);
      await service.saveNotification(NotificationModel(
        id: 'test_id_2',
        userId: 'user_1',
        type: 'system',
        title: 'Test 2',
        message: 'Test',
        createdAt: DateTime.now(),
        isRead: false,
      ));
       await service.saveNotification(NotificationModel(
        id: 'test_id_3',
        userId: 'user_2', // Different user
        type: 'system',
        title: 'Test 3',
        message: 'Test',
        createdAt: DateTime.now(),
        isRead: false,
      ));

      await service.markAllAsRead('user_1');

      final doc1 = await fakeFirestore.collection('notifications').doc('test_id').get();
      final doc2 = await fakeFirestore.collection('notifications').doc('test_id_2').get();
      final doc3 = await fakeFirestore.collection('notifications').doc('test_id_3').get();

      expect(doc1.data()?['isRead'], true);
      expect(doc2.data()?['isRead'], true);
      expect(doc3.data()?['isRead'], false); // Should remain false
    });

    test('getUnreadCount returns correct count', () async {
       await service.saveNotification(testNotification); // Unread
       await service.saveNotification(NotificationModel(
        id: 'test_id_2',
        userId: 'user_1',
        type: 'system',
        title: 'Test 2',
        message: 'Test',
        createdAt: DateTime.now(),
        isRead: true, // Read
      ));

      final count = await service.getUnreadCount('user_1');
      expect(count, 1);
    });

     test('deleteNotification removes notification', () async {
      await service.saveNotification(testNotification);

      await service.deleteNotification('test_id');

      final snapshot = await fakeFirestore.collection('notifications').doc('test_id').get();
      expect(snapshot.exists, false);
    });
  });
}

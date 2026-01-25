import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/models/notification_model.dart';

void main() {
  late NotificationStorageService service;
  late FakeFirebaseFirestore fakeFirestore;
  final testUserId = 'test_user_123';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = NotificationStorageService();
    service.setDependencies(
      firestore: fakeFirestore,
      userId: testUserId,
    );
  });

  tearDown(() {
    service.reset();
  });

  group('NotificationStorageService', () {
    test('saveNotification saves notification to Firestore', () async {
      final notification = NotificationModel(
        id: 'notif_1', // ID might be ignored by saveNotification as it uses add()
        userId: testUserId,
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        createdAt: DateTime.now(),
      );

      final docId = await service.saveNotification(notification);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .doc(docId)
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['title'], 'Test Title');
      expect(snapshot.data()?['message'], 'Test Message');
    });

    test('getNotifications retrieves notifications sorted by date', () async {
      // Add some notifications
      final now = DateTime.now();
      final n1 = NotificationModel(
        id: '1',
        userId: testUserId,
        type: 'system',
        title: 'Old',
        message: 'Old Message',
        createdAt: now.subtract(const Duration(hours: 2)),
      );
      final n2 = NotificationModel(
        id: '2',
        userId: testUserId,
        type: 'system',
        title: 'New',
        message: 'New Message',
        createdAt: now,
      );

      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .add(n1.toMap());
      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .add(n2.toMap());

      final notifications = await service.getNotifications();

      expect(notifications.length, 2);
      expect(notifications.first.title, 'New'); // Sorted descending
      expect(notifications.last.title, 'Old');
    });

    test('markAsRead updates isRead field', () async {
      final ref = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .add({
        'userId': testUserId,
        'type': 'system',
        'title': 'Test',
        'message': 'Message',
        'isRead': false,
        'createdAt': DateTime.now(),
      });

      await service.markAsRead(ref.id);

      final snapshot = await ref.get();
      expect(snapshot.data()?['isRead'], isTrue);
    });

    test('getUnreadCount returns correct count', () async {
      final ref = fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications');

      await ref.add({
        'userId': testUserId,
        'type': 'system',
        'title': 'Unread 1',
        'message': 'Message',
        'isRead': false,
        'createdAt': DateTime.now(),
      });
      await ref.add({
        'userId': testUserId,
        'type': 'system',
        'title': 'Unread 2',
        'message': 'Message',
        'isRead': false,
        'createdAt': DateTime.now(),
      });
      await ref.add({
        'userId': testUserId,
        'type': 'system',
        'title': 'Read',
        'message': 'Message',
        'isRead': true,
        'createdAt': DateTime.now(),
      });

      final count = await service.getUnreadCount();
      expect(count, 2);
    });

    test('markAllAsRead marks all unread notifications as read', () async {
      final ref = fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications');

      await ref.add({
        'userId': testUserId,
        'type': 'system',
        'title': 'Unread 1',
        'message': 'Message',
        'isRead': false,
        'createdAt': DateTime.now(),
      });
      await ref.add({
        'userId': testUserId,
        'type': 'system',
        'title': 'Unread 2',
        'message': 'Message',
        'isRead': false,
        'createdAt': DateTime.now(),
      });

      await service.markAllAsRead();

      final count = await service.getUnreadCount();
      expect(count, 0);

      final snapshot = await ref.get();
      for (var doc in snapshot.docs) {
        expect(doc.data()['isRead'], isTrue);
      }
    });
  });
}

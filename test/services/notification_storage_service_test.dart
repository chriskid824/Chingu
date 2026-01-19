import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

// Create a Fake User class
class FakeUser extends Fake implements User {
  @override
  final String uid;

  FakeUser({required this.uid});
}

// Create a Fake FirebaseAuth class
class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  final User? _user;

  FakeFirebaseAuth({User? user}) : _user = user;

  @override
  User? get currentUser => _user;
}

void main() {
  late NotificationStorageService service;
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseAuth fakeAuth;

  const String userId = 'test_user_id';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeAuth = FakeFirebaseAuth(user: FakeUser(uid: userId));

    service = NotificationStorageService();
    service.setMockInstances(firestore: fakeFirestore, auth: fakeAuth);
  });

  group('NotificationStorageService', () {
    test('saveNotification should add notification to Firestore', () async {
      final notification = NotificationModel(
        id: 'notif_1',
        userId: userId,
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        createdAt: DateTime.now(),
      );

      final id = await service.saveNotification(notification);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(id)
          .get();

      expect(snapshot.exists, true);
      expect(snapshot.data()?['title'], 'Test Title');
      expect(snapshot.data()?['message'], 'Test Message');
    });

    test('getNotifications should return notifications ordered by createdAt desc',
        () async {
      // Add notifications with different timestamps
      final now = DateTime.now();
      final olderDate = now.subtract(const Duration(hours: 1));
      final newerDate = now.add(const Duration(hours: 1));

      final notification1 = NotificationModel(
        id: 'n1',
        userId: userId,
        type: 'system',
        title: 'Older',
        message: 'Older msg',
        createdAt: olderDate,
      );

      final notification2 = NotificationModel(
        id: 'n2',
        userId: userId,
        type: 'system',
        title: 'Newer',
        message: 'Newer msg',
        createdAt: newerDate,
      );

      // We use saveNotifications to batch add or just add them manually to fakeFirestore
      // Note: saveNotification generates a new ID. saveNotifications uses the ID in the model.
      await service.saveNotifications([notification1, notification2]);

      final results = await service.getNotifications();

      expect(results.length, 2);
      expect(results[0].title, 'Newer'); // Should be first
      expect(results[1].title, 'Older');
    });

    test('getUnreadNotifications should return only unread notifications',
        () async {
      final notification1 = NotificationModel(
        id: 'n1',
        userId: userId,
        type: 'system',
        title: 'Unread',
        message: 'msg',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final notification2 = NotificationModel(
        id: 'n2',
        userId: userId,
        type: 'system',
        title: 'Read',
        message: 'msg',
        isRead: true,
        createdAt: DateTime.now(),
      );

      await service.saveNotifications([notification1, notification2]);

      final unread = await service.getUnreadNotifications();
      expect(unread.length, 1);
      expect(unread.first.title, 'Unread');

      final count = await service.getUnreadCount();
      expect(count, 1);
    });

    test('markAsRead should update isRead status', () async {
      final notification = NotificationModel(
        id: 'n1',
        userId: userId,
        type: 'system',
        title: 'Unread',
        message: 'msg',
        isRead: false,
        createdAt: DateTime.now(),
      );

      await service.saveNotifications([notification]);

      await service.markAsRead('n1');

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc('n1')
          .get();

      expect(snapshot.data()?['isRead'], true);
    });

    test('markAllAsRead should update all unread notifications', () async {
      final notifications = [
        NotificationModel(
          id: 'n1',
          userId: userId,
          type: 'system',
          title: 'Unread 1',
          message: 'msg',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        NotificationModel(
          id: 'n2',
          userId: userId,
          type: 'system',
          title: 'Unread 2',
          message: 'msg',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        NotificationModel(
          id: 'n3',
          userId: userId,
          type: 'system',
          title: 'Read',
          message: 'msg',
          isRead: true,
          createdAt: DateTime.now(),
        ),
      ];

      await service.saveNotifications(notifications);

      await service.markAllAsRead();

      final unread = await service.getUnreadNotifications();
      expect(unread, isEmpty);
    });

    test('deleteNotification should remove document', () async {
      final notification = NotificationModel(
        id: 'n1',
        userId: userId,
        type: 'system',
        title: 'To Delete',
        message: 'msg',
        createdAt: DateTime.now(),
      );

      await service.saveNotifications([notification]);

      await service.deleteNotification('n1');

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc('n1')
          .get();

      expect(snapshot.exists, false);
    });

    test('deleteOldNotifications should remove old documents', () async {
      final now = DateTime.now();
      final oldDate = now.subtract(const Duration(days: 40)); // Older than 30 days
      final recentDate = now.subtract(const Duration(days: 10));

      final oldNotif = NotificationModel(
        id: 'old',
        userId: userId,
        type: 'system',
        title: 'Old',
        message: 'msg',
        createdAt: oldDate,
      );

      final recentNotif = NotificationModel(
        id: 'recent',
        userId: userId,
        type: 'system',
        title: 'Recent',
        message: 'msg',
        createdAt: recentDate,
      );

      await service.saveNotifications([oldNotif, recentNotif]);

      final deletedCount = await service.deleteOldNotifications(olderThanDays: 30);
      expect(deletedCount, 1);

      final all = await service.getNotifications();
      expect(all.length, 1);
      expect(all.first.id, 'recent');
    });

    test('Helper methods should create notifications with correct types', () async {
      await service.createSystemNotification(title: 'Sys', message: 'Msg');
      var list = await service.getNotificationsByType('system');
      expect(list.length, 1);
      expect(list.first.title, 'Sys');

      await service.createMatchNotification(
        matchedUserName: 'Alice',
        matchedUserId: 'u2',
      );
      list = await service.getNotificationsByType('match');
      expect(list.length, 1);
      expect(list.first.message, contains('Alice'));
    });
  });
}

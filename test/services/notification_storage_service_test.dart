import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

// Manual mocks to avoid build_runner dependency
class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  final User? _user;
  FakeFirebaseAuth(this._user);

  @override
  User? get currentUser => _user;
}

class FakeUser extends Fake implements User {
  @override
  final String uid;

  FakeUser(this.uid);
}

void main() {
  late NotificationStorageService notificationService;
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseAuth fakeAuth;
  final String testUserId = 'test_user_123';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeAuth = FakeFirebaseAuth(FakeUser(testUserId));
    notificationService = NotificationStorageService();
    notificationService.setDependencies(
      firestore: fakeFirestore,
      auth: fakeAuth,
    );
  });

  group('NotificationStorageService', () {
    final testNotification = NotificationModel(
      id: 'notif_1',
      userId: testUserId,
      type: 'system',
      title: 'Welcome',
      message: 'Welcome to Chingu',
      createdAt: DateTime.now(),
      isRead: false,
    );

    test('saveNotification should add document to firestore', () async {
      final id = await notificationService.saveNotification(testNotification);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .doc(id)
          .get();

      expect(snapshot.exists, true);
      expect(snapshot.data()!['title'], 'Welcome');
      expect(snapshot.data()!['userId'], testUserId);
    });

    test('getNotifications should return list of notifications', () async {
      // Arrange
      await notificationService.saveNotification(testNotification);
      await notificationService.saveNotification(NotificationModel(
        id: 'notif_2',
        userId: testUserId,
        type: 'match',
        title: 'New Match',
        message: 'You have a match',
        createdAt: DateTime.now().add(const Duration(minutes: 1)),
        isRead: false,
      ));

      // Act
      final notifications = await notificationService.getNotifications();

      // Assert
      expect(notifications.length, 2);
      // Verify descending order (newest first)
      expect(notifications.first.title, 'New Match');
    });

    test('markAsRead should update isRead field', () async {
      // Arrange
      final id = await notificationService.saveNotification(testNotification);

      // Act
      await notificationService.markAsRead(id);

      // Assert
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .doc(id)
          .get();
      expect(snapshot.data()!['isRead'], true);
    });

    test('markAllAsRead should update all unread notifications', () async {
      // Arrange
      await notificationService.saveNotification(testNotification); // unread
      await notificationService.saveNotification(NotificationModel( // unread
        id: 'notif_2',
        userId: testUserId,
        type: 'system',
        title: 'Another',
        message: 'msg',
        createdAt: DateTime.now(),
        isRead: false,
      ));
      await notificationService.saveNotification(NotificationModel( // already read
        id: 'notif_3',
        userId: testUserId,
        type: 'system',
        title: 'Read',
        message: 'msg',
        createdAt: DateTime.now(),
        isRead: true,
      ));

      // Act
      await notificationService.markAllAsRead();

      // Assert
      final unreadCount = await notificationService.getUnreadCount();
      expect(unreadCount, 0);

      final notifications = await notificationService.getNotifications();
      expect(notifications.every((n) => n.isRead), true);
    });

    test('getUnreadCount should return correct count', () async {
      // Arrange
      await notificationService.saveNotification(testNotification); // unread
      await notificationService.saveNotification(NotificationModel( // read
        id: 'notif_2',
        userId: testUserId,
        type: 'system',
        title: 'Read',
        message: 'msg',
        createdAt: DateTime.now(),
        isRead: true,
      ));

      // Act
      final count = await notificationService.getUnreadCount();

      // Assert
      expect(count, 1);
    });

    test('deleteNotification should remove document', () async {
      // Arrange
      final id = await notificationService.saveNotification(testNotification);

      // Act
      await notificationService.deleteNotification(id);

      // Assert
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .doc(id)
          .get();
      expect(snapshot.exists, false);
    });

    test('createSystemNotification should create correct notification', () async {
       await notificationService.createSystemNotification(
         title: 'Sys Title',
         message: 'Sys Message',
         actionType: 'test',
       );

       final notifs = await notificationService.getNotifications();
       expect(notifs.length, 1);
       expect(notifs.first.type, 'system');
       expect(notifs.first.title, 'Sys Title');
       expect(notifs.first.actionType, 'test');
    });
  });
}

import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

// Manual mocks to avoid build_runner overhead
class MockUser extends Fake implements User {
  @override
  final String uid;
  MockUser(this.uid);
}

class MockFirebaseAuth extends Fake implements FirebaseAuth {
  final User? _user;
  MockFirebaseAuth(this._user);

  @override
  User? get currentUser => _user;
}

void main() {
  late NotificationStorageService notificationService;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  final testUserId = 'test_user_id';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(MockUser(testUserId));

    notificationService = NotificationStorageService();
    notificationService.setFirestoreInstance(fakeFirestore);
    notificationService.setAuthInstance(mockAuth);
  });

  group('NotificationStorageService', () {
    test('saveNotification should save to correct collection', () async {
      final notification = NotificationModel(
        id: '',
        userId: testUserId,
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        createdAt: DateTime.now(),
      );

      final id = await notificationService.saveNotification(notification);

      final docSnapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .doc(id)
          .get();

      expect(docSnapshot.exists, isTrue);
      expect(docSnapshot.data()?['title'], 'Test Title');
      expect(docSnapshot.data()?['userId'], testUserId);
    });

    test('getNotifications should return stored notifications ordered by date', () async {
      // Add multiple notifications
      final now = DateTime.now();
      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .add({
        'title': 'Old',
        'type': 'system',
        'message': 'Old msg',
        'createdAt': now.subtract(Duration(days: 1)),
        'isRead': false,
      });

      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .add({
        'title': 'New',
        'type': 'system',
        'message': 'New msg',
        'createdAt': now,
        'isRead': false,
      });

      final notifications = await notificationService.getNotifications();

      expect(notifications.length, 2);
      expect(notifications.first.title, 'New'); // descending order
      expect(notifications.last.title, 'Old');
    });

    test('markAsRead should update isRead field', () async {
      final ref = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .add({
        'title': 'Test',
        'type': 'system',
        'message': 'Msg',
        'createdAt': DateTime.now(),
        'isRead': false,
      });

      await notificationService.markAsRead(ref.id);

      final doc = await ref.get();
      expect(doc.data()?['isRead'], true);
    });

    test('getUnreadCount should return correct count', () async {
      // 1 Unread
      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .add({
        'isRead': false,
        'createdAt': DateTime.now(),
      });
      // 1 Read
      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .add({
        'isRead': true,
        'createdAt': DateTime.now(),
      });

      final count = await notificationService.getUnreadCount();
      expect(count, 1);
    });

    test('createSystemNotification should create notification', () async {
      await notificationService.createSystemNotification(
        title: 'System',
        message: 'Hello',
      );

      final query = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .get();

      expect(query.docs.length, 1);
      expect(query.docs.first.data()['type'], 'system');
      expect(query.docs.first.data()['title'], 'System');
    });
  });
}

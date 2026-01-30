import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Create a mock for FirebaseAuth
class MockFirebaseAuth extends Mock implements FirebaseAuth {
  @override
  User? get currentUser => _currentUser;

  User? _currentUser;

  set mockUser(User? user) => _currentUser = user;
}

// Create a mock for User
class MockUser extends Mock implements User {
  @override
  String get uid => 'test-user-id';
}

void main() {
  late NotificationStorageService service;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockAuth.mockUser = mockUser;

    service = NotificationStorageService();
    service.firestore = fakeFirestore;
    service.auth = mockAuth;
  });

  group('NotificationStorageService', () {
    test('saveNotification stores notification in correct path', () async {
      final notification = NotificationModel(
        id: '1',
        userId: 'test-user-id',
        type: 'system',
        title: 'Test',
        message: 'Message',
        createdAt: DateTime.now(),
      );

      final id = await service.saveNotification(notification);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .doc(id)
          .get();

      expect(snapshot.exists, true);
      expect(snapshot.data()!['title'], 'Test');
    });

    test('getNotifications returns sorted notifications', () async {
      final now = DateTime.now();
      // Add multiple notifications
      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .add({
        'title': 'Old',
        'createdAt': Timestamp.fromDate(now.subtract(Duration(hours: 1))),
        'isRead': false,
      });

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .add({
        'title': 'New',
        'createdAt': Timestamp.fromDate(now),
        'isRead': false,
      });

      final notifications = await service.getNotifications();

      expect(notifications.length, 2);
      expect(notifications[0].title, 'New'); // Sorted descending
      expect(notifications[1].title, 'Old');
    });

    test('getUnreadCount returns correct count', () async {
       await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .add({
        'title': 'Unread 1',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .add({
        'title': 'Read 1',
        'isRead': true,
        'createdAt': Timestamp.now(),
      });

      final count = await service.getUnreadCount();
      expect(count, 1);
    });

    test('markAsRead updates isRead field', () async {
      final ref = await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .add({
        'title': 'Unread',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      await service.markAsRead(ref.id);

      final doc = await ref.get();
      expect(doc.data()!['isRead'], true);
    });

    test('markAllAsRead updates all unread notifications', () async {
       await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .add({
        'title': 'Unread 1',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .add({
        'title': 'Unread 2',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      await service.markAllAsRead();

      final snapshot = await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      expect(snapshot.docs.isEmpty, true);
    });

    test('createSystemNotification creates a valid notification', () async {
      await service.createSystemNotification(
        title: 'Sys Title',
        message: 'Sys Message',
        actionType: 'test_action',
      );

      final snapshot = await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .get();

      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['title'], 'Sys Title');
      expect(data['type'], 'system');
      expect(data['actionType'], 'test_action');
    });

    test('deleteNotification removes document', () async {
       final ref = await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .add({
        'title': 'To Delete',
        'createdAt': Timestamp.now(),
      });

      await service.deleteNotification(ref.id);

      final doc = await ref.get();
      expect(doc.exists, false);
    });

    test('deleteAllNotifications removes all documents', () async {
       await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .add({
        'title': '1',
      });

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .add({
        'title': '2',
      });

      await service.deleteAllNotifications();

      final snapshot = await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .get();

      expect(snapshot.docs.isEmpty, true);
    });
  });
}

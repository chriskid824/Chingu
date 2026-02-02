import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  const String testUserId = 'test-user-123';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(testUserId);

    service = NotificationStorageService();
    service.setMockInstances(firestore: fakeFirestore, auth: mockAuth);
  });

  group('NotificationStorageService', () {
    test('saveNotification adds notification to Firestore', () async {
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

      expect(id, isNotEmpty);
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications')
          .doc(id)
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()!['title'], 'Test Title');
    });

    test('getNotifications returns notifications ordered by date', () async {
      final ref = fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications');

      await ref.add({
        'title': 'Old',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'isRead': false,
        'type': 'system',
        'userId': testUserId,
        'message': 'old msg'
      });

      await ref.add({
        'title': 'New',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
        'type': 'system',
        'userId': testUserId,
        'message': 'new msg'
      });

      final notifications = await service.getNotifications();
      expect(notifications.length, 2);
      expect(notifications.first.title, 'New');
      expect(notifications.last.title, 'Old');
    });

    test('getUnreadNotifications returns only unread', () async {
       final ref = fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications');

      await ref.add({
        'title': 'Unread',
        'createdAt': Timestamp.now(),
        'isRead': false,
        'type': 'system',
        'userId': testUserId,
        'message': 'msg'
      });

      await ref.add({
        'title': 'Read',
        'createdAt': Timestamp.now(),
        'isRead': true,
        'type': 'system',
        'userId': testUserId,
        'message': 'msg'
      });

      final unread = await service.getUnreadNotifications();
      expect(unread.length, 1);
      expect(unread.first.title, 'Unread');
    });

    test('getUnreadCount returns correct count', () async {
       final ref = fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications');

      await ref.add({
        'title': 'Unread 1',
        'isRead': false,
        'createdAt': Timestamp.now(),
        'userId': testUserId,
        'type': 'system',
        'message': 'msg'
      });
      await ref.add({
        'title': 'Unread 2',
        'isRead': false,
        'createdAt': Timestamp.now(),
        'userId': testUserId,
        'type': 'system',
        'message': 'msg'
      });
      await ref.add({
        'title': 'Read',
        'isRead': true,
        'createdAt': Timestamp.now(),
        'userId': testUserId,
        'type': 'system',
        'message': 'msg'
      });

      final count = await service.getUnreadCount();
      expect(count, 2);
    });

    test('markAsRead updates isRead field', () async {
      final ref = fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications');

      final docRef = await ref.add({
        'title': 'Unread',
        'isRead': false,
        'createdAt': Timestamp.now(),
        'userId': testUserId,
        'type': 'system',
        'message': 'msg'
      });

      await service.markAsRead(docRef.id);

      final snapshot = await docRef.get();
      expect(snapshot.data()!['isRead'], isTrue);
    });

    test('markAllAsRead updates all unread notifications', () async {
      final ref = fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications');

      await ref.add({
        'title': 'Unread 1',
        'isRead': false,
        'createdAt': Timestamp.now(),
        'userId': testUserId,
        'type': 'system',
        'message': 'msg'
      });
      await ref.add({
        'title': 'Unread 2',
        'isRead': false,
        'createdAt': Timestamp.now(),
        'userId': testUserId,
        'type': 'system',
        'message': 'msg'
      });

      await service.markAllAsRead();

      final snapshot = await ref.get();
      for (final doc in snapshot.docs) {
        expect(doc.data()['isRead'], isTrue);
      }
    });

     test('deleteNotification removes document', () async {
      final ref = fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications');

      final docRef = await ref.add({
        'title': 'To Delete',
        'isRead': false,
        'createdAt': Timestamp.now(),
        'userId': testUserId,
        'type': 'system',
        'message': 'msg'
      });

      await service.deleteNotification(docRef.id);

      final snapshot = await docRef.get();
      expect(snapshot.exists, isFalse);
    });
  });
}

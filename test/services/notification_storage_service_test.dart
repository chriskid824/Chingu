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

  const String userId = 'test_user_id';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    service = NotificationStorageService();

    service.firestore = fakeFirestore;
    service.auth = mockAuth;

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(userId);
  });

  group('NotificationStorageService', () {
    test('saveNotification stores notification in Firestore', () async {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: 'system',
        title: 'Test Notification',
        message: 'This is a test',
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
      expect(snapshot.data()?['title'], 'Test Notification');
      expect(snapshot.data()?['isRead'], false);
    });

    test('getNotifications retrieves notifications ordered by date', () async {
      // Add a few notifications
      final ref = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      await ref.add({
        'userId': userId,
        'title': 'Old',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
        'isRead': false,
      });

      await ref.add({
        'userId': userId,
        'title': 'New',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
      });

      final notifications = await service.getNotifications();

      expect(notifications.length, 2);
      expect(notifications.first.title, 'New'); // Should be newest first
      expect(notifications.last.title, 'Old');
    });

    test('markAsRead updates isRead field', () async {
      final ref = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      final doc = await ref.add({
        'userId': userId,
        'title': 'Test',
        'createdAt': Timestamp.now(),
        'isRead': false,
      });

      await service.markAsRead(doc.id);

      final snapshot = await doc.get();
      expect(snapshot.data()?['isRead'], true);
    });

    test('getUnreadCount returns correct count', () async {
      final ref = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      await ref.add({'isRead': false, 'createdAt': Timestamp.now()});
      await ref.add({'isRead': true, 'createdAt': Timestamp.now()});
      await ref.add({'isRead': false, 'createdAt': Timestamp.now()});

      final count = await service.getUnreadCount();
      expect(count, 2);
    });

    test('deleteNotification removes document', () async {
       final ref = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      final doc = await ref.add({
        'userId': userId,
        'title': 'To Delete',
        'createdAt': Timestamp.now(),
      });

      await service.deleteNotification(doc.id);

      final snapshot = await doc.get();
      expect(snapshot.exists, false);
    });

    test('createSystemNotification creates a system notification', () async {
      await service.createSystemNotification(
        title: 'System Alert',
        message: 'Maintenance soon',
      );

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['type'], 'system');
      expect(data['title'], 'System Alert');
      expect(data['message'], 'Maintenance soon');
    });
  });
}

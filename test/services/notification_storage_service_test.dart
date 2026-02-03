import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseAuth, User])
import 'notification_storage_service_test.mocks.dart';

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

    // Mock user setup
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(userId);

    service = NotificationStorageService();
    service.firestore = fakeFirestore;
    service.auth = mockAuth;
  });

  group('NotificationStorageService', () {
    test('saveNotification stores notification in root notifications collection', () async {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: 'system',
        title: 'Test',
        message: 'Message',
        createdAt: DateTime.now(),
      );

      final id = await service.saveNotification(notification);

      final doc = await fakeFirestore.collection('notifications').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['userId'], userId);
      expect(doc.data()!['title'], 'Test');
    });

    test('getNotifications returns only user notifications', () async {
      // Add notification for current user
      await fakeFirestore.collection('notifications').add({
        'userId': userId,
        'title': 'User notification',
        'type': 'system',
        'message': 'test',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      // Add notification for another user
      await fakeFirestore.collection('notifications').add({
        'userId': 'other_user',
        'title': 'Other notification',
        'type': 'system',
        'message': 'test',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      final notifications = await service.getNotifications();

      expect(notifications.length, 1);
      expect(notifications.first.userId, userId);
      expect(notifications.first.title, 'User notification');
    });

    test('markAsRead updates the notification', () async {
       final ref = await fakeFirestore.collection('notifications').add({
        'userId': userId,
        'title': 'Test',
        'isRead': false,
        'type': 'system',
        'message': 'test',
        'createdAt': Timestamp.now(),
      });

      await service.markAsRead(ref.id);

      final doc = await ref.get();
      expect(doc.data()!['isRead'], true);
    });

    test('getUnreadCount returns correct count', () async {
      // Unread
       await fakeFirestore.collection('notifications').add({
        'userId': userId,
        'isRead': false,
        'type': 'system',
        'message': 'test',
        'title': '1',
        'createdAt': Timestamp.now(),
      });
      // Read
       await fakeFirestore.collection('notifications').add({
        'userId': userId,
        'isRead': true,
        'type': 'system',
        'message': 'test',
        'title': '2',
        'createdAt': Timestamp.now(),
      });
      // Other user unread
       await fakeFirestore.collection('notifications').add({
        'userId': 'other',
        'isRead': false,
        'type': 'system',
        'message': 'test',
        'title': '3',
        'createdAt': Timestamp.now(),
      });

      final count = await service.getUnreadCount();
      expect(count, 1);
    });

    test('watchNotifications streams updates', () async {
      // Initial data
      await fakeFirestore.collection('notifications').add({
        'userId': userId,
        'title': 'Initial',
        'type': 'system',
        'message': 'test',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      final stream = service.watchNotifications();

      expectLater(
        stream,
        emitsInOrder([
          isA<List<NotificationModel>>().having((l) => l.length, 'length', 1),
          isA<List<NotificationModel>>().having((l) => l.length, 'length', 2),
        ]),
      );

      // Add new data
      await Future.delayed(Duration(milliseconds: 100));
      await fakeFirestore.collection('notifications').add({
        'userId': userId,
        'title': 'New',
        'type': 'system',
        'message': 'test',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
    });
  });
}

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

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Mock authenticated user
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test_user_id');

    service = NotificationStorageService();
    // Inject mocks
    service.setInstancesForTesting(firestore: fakeFirestore, auth: mockAuth);
  });

  group('NotificationStorageService', () {
    test('saveNotification should save notification to Firestore', () async {
      final notification = NotificationModel(
        id: '1',
        userId: 'test_user_id',
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        isRead: false,
        createdAt: DateTime.now(),
      );

      await service.saveNotification(notification);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('notifications')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['title'], 'Test Title');
    });

    test('getNotifications should return notifications', () async {
      // Add a notification directly to fake firestore
      await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('notifications')
          .add({
        'userId': 'test_user_id',
        'type': 'system',
        'title': 'Test Title',
        'message': 'Test Message',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      final notifications = await service.getNotifications();

      expect(notifications.length, 1);
      expect(notifications.first.title, 'Test Title');
    });

    test('markAsRead should update isRead status', () async {
      final docRef = await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('notifications')
          .add({
        'userId': 'test_user_id',
        'type': 'system',
        'title': 'Test Title',
        'message': 'Test Message',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      await service.markAsRead(docRef.id);

      final doc = await docRef.get();
      expect(doc.data()!['isRead'], true);
    });
  });
}

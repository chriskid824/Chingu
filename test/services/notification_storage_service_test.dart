import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import the generated mock file
import 'notification_storage_service_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User])
void main() {
  late NotificationStorageService service;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  const String testUserId = 'test_user_123';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Setup Mock User
    when(mockUser.uid).thenReturn(testUserId);
    when(mockAuth.currentUser).thenReturn(mockUser);

    service = NotificationStorageService();
    service.setMockInstances(firestore: fakeFirestore, auth: mockAuth);
  });

  group('NotificationStorageService', () {
    test('saveNotification adds a document to Firestore', () async {
      final notification = NotificationModel(
        id: '', // Service should generate ID or Firestore will
        userId: testUserId,
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        isRead: false,
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
      expect(snapshot.data()?['userId'], testUserId);
    });

    test('getNotifications retrieves notifications in correct order', () async {
      // Add multiple notifications
      final now = DateTime.now();
      final n1 = NotificationModel(
        id: '1',
        userId: testUserId,
        type: 'system',
        title: 'Old',
        message: 'Old Message',
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 1)),
      );
      final n2 = NotificationModel(
        id: '2',
        userId: testUserId,
        type: 'system',
        title: 'New',
        message: 'New Message',
        isRead: false,
        createdAt: now,
      );

      // We manually add them to fakeFirestore to control IDs and data
      final colRef = fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications');

      await colRef.doc(n1.id).set(n1.toMap());
      await colRef.doc(n2.id).set(n2.toMap());

      final results = await service.getNotifications();

      expect(results.length, 2);
      // Ordered by createdAt descending
      expect(results[0].id, n2.id); // Newest first
      expect(results[1].id, n1.id);
    });

    test('markAsRead updates the isRead field', () async {
      final n1 = NotificationModel(
        id: '1',
        userId: testUserId,
        type: 'system',
        title: 'Unread',
        message: 'Unread Message',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final colRef = fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications');
      await colRef.doc(n1.id).set(n1.toMap());

      await service.markAsRead('1');

      final snapshot = await colRef.doc('1').get();
      expect(snapshot.data()?['isRead'], true);
    });

    test('getUnreadCount returns correct count', () async {
      final colRef = fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications');

      await colRef.add({
        'title': 'Read',
        'isRead': true,
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'type': 'system',
        'message': 'msg',
        'id': '1',
      });
      await colRef.add({
        'title': 'Unread 1',
        'isRead': false,
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'type': 'system',
        'message': 'msg',
        'id': '2',
      });
       await colRef.add({
        'title': 'Unread 2',
        'isRead': false,
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'type': 'system',
        'message': 'msg',
        'id': '3',
      });

      final count = await service.getUnreadCount();
      expect(count, 2);
    });

    test('getNotificationsByType filters correctly', () async {
       final colRef = fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('notifications');

      await colRef.add({
        'type': 'match',
        'title': 'Match',
        'message': 'msg',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'isRead': false,
        'id': '1',
      });
      await colRef.add({
        'type': 'system',
        'title': 'System',
        'message': 'msg',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'isRead': false,
        'id': '2',
      });

      final matches = await service.getNotificationsByType('match');
      expect(matches.length, 1);
      expect(matches.first.type, 'match');
    });
  });
}

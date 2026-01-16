import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Manual mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {
  @override
  User? get currentUser => super.noSuchMethod(
        Invocation.getter(#currentUser),
        returnValue: null,
      );
}

class MockUser extends Mock implements User {
  @override
  String get uid => super.noSuchMethod(
        Invocation.getter(#uid),
        returnValue: '',
      );
}

void main() {
  late NotificationStorageService notificationService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late FakeFirebaseFirestore fakeFirestore;

  const String userId = 'test_user_id';

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    fakeFirestore = FakeFirebaseFirestore();

    // Mock authentication
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(userId);

    notificationService = NotificationStorageService();
    notificationService.setFirestoreInstance(fakeFirestore);
    notificationService.setAuthInstance(mockAuth);
  });

  group('saveNotification', () {
    test('should save notification to correct collection', () async {
      final notification = NotificationModel(
        id: '1', // ID is ignored when using saveNotification (add)
        userId: userId,
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        createdAt: DateTime.now(),
      );

      final id = await notificationService.saveNotification(notification);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(id)
          .get();

      expect(snapshot.exists, true);
      expect(snapshot.data()?['title'], 'Test Title');
      expect(snapshot.data()?['type'], 'system');
    });

    test('should throw exception if user is not authenticated', () async {
      when(mockAuth.currentUser).thenReturn(null);

      final notification = NotificationModel(
        id: '1',
        userId: userId,
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        createdAt: DateTime.now(),
      );

      expect(
        () => notificationService.saveNotification(notification),
        throwsException,
      );
    });
  });

  group('getNotifications', () {
    test('should retrieve notifications ordered by createdAt desc', () async {
      // Add test data
      final colRef = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      await colRef.add({
        'title': 'Old',
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
        'isRead': false,
        'userId': userId,
        'type': 'system',
        'message': 'Old msg',
      });

      await colRef.add({
        'title': 'New',
        'createdAt': DateTime.now(),
        'isRead': false,
        'userId': userId,
        'type': 'system',
        'message': 'New msg',
      });

      final notifications = await notificationService.getNotifications();

      expect(notifications.length, 2);
      expect(notifications.first.title, 'New');
      expect(notifications.last.title, 'Old');
    });
  });

  group('markAsRead', () {
    test('should mark notification as read', () async {
      final colRef = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      final docRef = await colRef.add({
        'title': 'Test',
        'isRead': false,
        'userId': userId,
        'type': 'system',
        'message': 'msg',
        'createdAt': DateTime.now(),
      });

      await notificationService.markAsRead(docRef.id);

      final snapshot = await docRef.get();
      expect(snapshot.data()?['isRead'], true);
    });
  });

  group('getUnreadCount', () {
    test('should return correct count of unread notifications', () async {
      final colRef = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      await colRef.add({
        'title': 'Unread 1',
        'isRead': false,
        'createdAt': DateTime.now(),
        'userId': userId,
        'type': 'system',
        'message': 'msg',
      });
      await colRef.add({
        'title': 'Read 1',
        'isRead': true,
        'createdAt': DateTime.now(),
        'userId': userId,
        'type': 'system',
        'message': 'msg',
      });
      await colRef.add({
        'title': 'Unread 2',
        'isRead': false,
        'createdAt': DateTime.now(),
        'userId': userId,
        'type': 'system',
        'message': 'msg',
      });

      final count = await notificationService.getUnreadCount();

      expect(count, 2);
    });
  });

  group('markAllAsRead', () {
    test('should mark all unread notifications as read', () async {
      final colRef = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      await colRef.add({
        'title': 'Unread 1',
        'isRead': false,
        'createdAt': DateTime.now(),
        'userId': userId,
        'type': 'system',
        'message': 'msg',
      });
      await colRef.add({
        'title': 'Unread 2',
        'isRead': false,
        'createdAt': DateTime.now(),
        'userId': userId,
        'type': 'system',
        'message': 'msg',
      });

      await notificationService.markAllAsRead();

      final snapshot = await colRef.get();
      final allRead = snapshot.docs.every((doc) => doc.data()['isRead'] == true);
      expect(allRead, true);
    });
  });
}

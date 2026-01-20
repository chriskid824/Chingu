import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/models/notification_model.dart';

// Manual mocks/fakes to avoid build_runner
class FakeUser extends Fake implements User {
  @override
  final String uid;

  FakeUser({required this.uid});
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  final User? _currentUser;

  FakeFirebaseAuth({User? currentUser}) : _currentUser = currentUser;

  @override
  User? get currentUser => _currentUser;
}

void main() {
  late NotificationStorageService service;
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseAuth fakeAuth;
  final String testUserId = 'test_user_123';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeAuth = FakeFirebaseAuth(currentUser: FakeUser(uid: testUserId));
    service = NotificationStorageService();
    // Inject dependencies
    service.firestoreInstance = fakeFirestore;
    service.authInstance = fakeAuth;
  });

  group('NotificationStorageService', () {
    test('saveNotification should save to root notifications collection', () async {
      final notification = NotificationModel(
        id: '1', // ID will be ignored/overwritten by add()
        userId: testUserId,
        type: 'system',
        title: 'Test',
        message: 'Hello',
        createdAt: DateTime.now(),
        isRead: false,
      );

      final id = await service.saveNotification(notification);

      final snapshot = await fakeFirestore.collection('notifications').doc(id).get();
      expect(snapshot.exists, isTrue);
      expect(snapshot.data()!['userId'], testUserId);
      expect(snapshot.data()!['title'], 'Test');
    });

    test('getNotifications should filter by userId', () async {
      // Add notification for current user
      await fakeFirestore.collection('notifications').add({
        'userId': testUserId,
        'title': 'My Notification',
        'message': 'Mine',
        'createdAt': DateTime.now(),
        'isRead': false,
        'type': 'system',
      });

      // Add notification for another user
      await fakeFirestore.collection('notifications').add({
        'userId': 'other_user',
        'title': 'Other Notification',
        'message': 'Not Mine',
        'createdAt': DateTime.now(),
        'isRead': false,
        'type': 'system',
      });

      final notifications = await service.getNotifications();

      expect(notifications.length, 1);
      expect(notifications.first.title, 'My Notification');
      expect(notifications.first.userId, testUserId);
    });

    test('getUnreadCount should count only unread notifications for user', () async {
      // Unread for user
      await fakeFirestore.collection('notifications').add({
        'userId': testUserId,
        'isRead': false,
        'createdAt': DateTime.now(),
        'type': 'system',
        'title': '1', 'message': '1',
      });
      // Read for user
      await fakeFirestore.collection('notifications').add({
        'userId': testUserId,
        'isRead': true,
        'createdAt': DateTime.now(),
        'type': 'system',
        'title': '2', 'message': '2',
      });
      // Unread for other user
      await fakeFirestore.collection('notifications').add({
        'userId': 'other',
        'isRead': false,
        'createdAt': DateTime.now(),
        'type': 'system',
        'title': '3', 'message': '3',
      });

      final count = await service.getUnreadCount();
      expect(count, 1);
    });

    test('markAsRead should update isRead to true', () async {
      final ref = await fakeFirestore.collection('notifications').add({
        'userId': testUserId,
        'isRead': false,
        'createdAt': DateTime.now(),
        'type': 'system',
        'title': 'Unread', 'message': 'Unread',
      });

      await service.markAsRead(ref.id);

      final snapshot = await ref.get();
      expect(snapshot.data()!['isRead'], true);
    });

    test('createSystemNotification should create document in collection', () async {
      await service.createSystemNotification(
        title: 'System',
        message: 'Welcome',
      );

      final query = await fakeFirestore
          .collection('notifications')
          .where('userId', isEqualTo: testUserId)
          .get();

      expect(query.docs.length, 1);
      expect(query.docs.first.data()['type'], 'system');
      expect(query.docs.first.data()['title'], 'System');
    });
  });
}

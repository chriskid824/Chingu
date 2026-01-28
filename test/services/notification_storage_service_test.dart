import 'package:chingu/models/models.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// 簡單的 Mock 實現，避免使用 build_runner
class MockUser extends Fake implements User {
  @override
  final String uid;

  MockUser(this.uid);
}

class MockFirebaseAuth extends Fake implements FirebaseAuth {
  User? _currentUser;

  void setCurrentUser(User? user) {
    _currentUser = user;
  }

  @override
  User? get currentUser => _currentUser;
}

void main() {
  late NotificationStorageService service;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser('test-user-id');
    mockAuth.setCurrentUser(mockUser);

    service = NotificationStorageService();
    service.firestoreInstance = fakeFirestore;
    service.authInstance = mockAuth;
  });

  group('NotificationStorageService', () {
    final notification = NotificationModel(
      id: 'notif-1',
      userId: 'test-user-id',
      type: 'match',
      title: 'New Match',
      message: 'You have a match!',
      createdAt: DateTime.now(),
    );

    test('saveNotification should save when user allows it', () async {
      // Setup user with settings allowing 'match' (default is true)
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'email': 'test@example.com',
        'age': 25,
        'gender': 'male',
        'job': 'Dev',
        'interests': [],
        'country': 'TW',
        'city': 'Taipei',
        'district': 'Xinyi',
        'preferredMatchType': 'any',
        'minAge': 18,
        'maxAge': 30,
        'budgetRange': 1,
        'isActive': true,
        'createdAt': DateTime.now(),
        'lastLogin': DateTime.now(),
        'notificationSettings': {
          'newMatch': true,
        }
      });

      await service.saveNotification(notification);

      final snapshot = await fakeFirestore.collection('notifications').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first['title'], 'New Match');
    });

    test('saveNotification should NOT save when user disables it', () async {
      // Setup user with settings disallowing 'match'
      await fakeFirestore.collection('users').doc('test-user-id').set({
        'name': 'Test User',
        'email': 'test@example.com',
        'age': 25,
        'gender': 'male',
        'job': 'Dev',
        'interests': [],
        'country': 'TW',
        'city': 'Taipei',
        'district': 'Xinyi',
        'preferredMatchType': 'any',
        'minAge': 18,
        'maxAge': 30,
        'budgetRange': 1,
        'isActive': true,
        'createdAt': DateTime.now(),
        'lastLogin': DateTime.now(),
        'notificationSettings': {
          'newMatch': false,
        }
      });

      await service.saveNotification(notification);

      final snapshot = await fakeFirestore.collection('notifications').get();
      expect(snapshot.docs.length, 0);
    });

    test('getNotificationsStream should return notifications for current user', () async {
      // Add notifications
      await fakeFirestore.collection('notifications').add(notification.toMap());
      // Add another for different user
      await fakeFirestore.collection('notifications').add({
        ...notification.toMap(),
        'userId': 'other-user',
      });

      final stream = service.getNotificationsStream();
      final notifications = await stream.first;

      expect(notifications.length, 1);
      expect(notifications.first.userId, 'test-user-id');
    });

    test('markAsRead should update isRead field', () async {
      final ref = await fakeFirestore.collection('notifications').add(notification.toMap());

      await service.markAsRead(ref.id);

      final doc = await ref.get();
      expect(doc.data()!['isRead'], true);
    });

    test('markAllAsRead should update all unread notifications for user', () async {
      await fakeFirestore.collection('notifications').add(notification.toMap());
      await fakeFirestore.collection('notifications').add(notification.toMap());

      // Another user's notification (should not be touched)
      final otherRef = await fakeFirestore.collection('notifications').add({
        ...notification.toMap(),
        'userId': 'other-user',
      });

      await service.markAllAsRead();

      final snapshot = await fakeFirestore.collection('notifications').where('userId', isEqualTo: 'test-user-id').get();
      expect(snapshot.docs.every((d) => d['isRead'] == true), true);

      final otherDoc = await otherRef.get();
      expect(otherDoc.data()!['isRead'], false);
    });

    test('getUnreadCountStream should return correct count', () async {
      // 2 Unread
      await fakeFirestore.collection('notifications').add(notification.toMap());
      await fakeFirestore.collection('notifications').add(notification.toMap());
      // 1 Read
      await fakeFirestore.collection('notifications').add({
        ...notification.toMap(),
        'isRead': true,
      });

      final stream = service.getUnreadCountStream();
      final count = await stream.first;

      expect(count, 2);
    });
  });
}

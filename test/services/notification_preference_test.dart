import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late NotificationStorageService service;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = NotificationStorageService();
    service.firestoreInstance = fakeFirestore;
  });

  Map<String, dynamic> createUserMap(String userId, Map<String, dynamic> settings) {
    return {
      'uid': userId,
      'name': 'Test User',
      'email': 'test@example.com',
      'age': 25,
      'gender': 'male',
      'job': 'Engineer',
      'interests': ['coding'],
      'country': 'Taiwan',
      'city': 'Taipei',
      'district': 'Xinyi',
      'preferredMatchType': 'any',
      'minAge': 18,
      'maxAge': 30,
      'budgetRange': 1,
      'createdAt': Timestamp.now(),
      'lastLogin': Timestamp.now(),
      'notificationSettings': settings,
    };
  }

  group('NotificationStorageService Preferences', () {
    test('should send notification when enabled', () async {
      final userId = 'user1';
      await fakeFirestore.collection('users').doc(userId).set(createUserMap(userId, {
        'pushEnabled': true,
        'newMatch': true,
        'matchSuccess': true,
      }));

      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: 'match',
        title: 'New Match',
        message: 'You have a new match',
        createdAt: DateTime.now(),
      );

      final id = await service.saveNotification(notification);

      expect(id, isNotEmpty);

      final docs = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      expect(docs.docs.length, 1);
    });

    test('should NOT send notification when type disabled', () async {
      final userId = 'user2';
      // Disable match notifications
      await fakeFirestore.collection('users').doc(userId).set(createUserMap(userId, {
        'pushEnabled': true,
        'newMatch': false,
        'matchSuccess': false,
      }));

      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: 'match',
        title: 'New Match',
        message: 'You have a new match',
        createdAt: DateTime.now(),
      );

      final id = await service.saveNotification(notification);

      expect(id, isEmpty);

      final docs = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      expect(docs.docs.length, 0);
    });

    test('should NOT send notification when push disabled globally', () async {
      final userId = 'user3';
      // Disable push globally
      await fakeFirestore.collection('users').doc(userId).set(createUserMap(userId, {
        'pushEnabled': false,
        'newMatch': true,
      }));

      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: 'match',
        title: 'New Match',
        message: 'You have a new match',
        createdAt: DateTime.now(),
      );

      final id = await service.saveNotification(notification);

      expect(id, isEmpty);

      final docs = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      expect(docs.docs.length, 0);
    });

    test('createMatchNotification uses targetUserId and respects settings', () async {
       final userId = 'user4';
       // Enable match
       await fakeFirestore.collection('users').doc(userId).set(createUserMap(userId, {
        'pushEnabled': true,
        'newMatch': true,
        'matchSuccess': true,
       }));

       await service.createMatchNotification(
         targetUserId: userId,
         matchedUserName: 'Alice',
         matchedUserId: 'alice123',
       );

       final docs = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
       expect(docs.docs.length, 1);
       expect(docs.docs.first['type'], 'match');
    });

     test('createMatchNotification respects disabled settings', () async {
       final userId = 'user5';
       // Disable match
       await fakeFirestore.collection('users').doc(userId).set(createUserMap(userId, {
        'pushEnabled': true,
        'newMatch': false,
        'matchSuccess': false,
       }));

       await service.createMatchNotification(
         targetUserId: userId,
         matchedUserName: 'Alice',
         matchedUserId: 'alice123',
       );

       final docs = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
       expect(docs.docs.length, 0);
    });
  });
}

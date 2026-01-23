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
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late FakeFirebaseFirestore fakeFirestore;

  const String userId = 'test_user_id';

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    fakeFirestore = FakeFirebaseFirestore();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(userId);

    service = NotificationStorageService();
    service.setMockInstances(firestore: fakeFirestore, auth: mockAuth);
  });

  group('NotificationStorageService', () {
    test('saveNotification saves notification to firestore', () async {
      final notification = NotificationModel(
        id: '1',
        userId: userId,
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        createdAt: DateTime.now(),
      );

      final id = await service.saveNotification(notification);

      expect(id, isNotEmpty);
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(id)
          .get();
      expect(snapshot.exists, true);
      expect(snapshot.data()!['title'], 'Test Title');
    });

    test('saveNotifications saves multiple notifications', () async {
      final n1 = NotificationModel(
        id: 'n1',
        userId: userId,
        type: 'system',
        title: 'Title 1',
        message: 'Message 1',
        createdAt: DateTime.now(),
      );
      final n2 = NotificationModel(
        id: '', // Empty ID should generate new ID
        userId: userId,
        type: 'system',
        title: 'Title 2',
        message: 'Message 2',
        createdAt: DateTime.now(),
      );

      await service.saveNotifications([n1, n2]);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      expect(snapshot.docs.length, 2);
      final doc1 = snapshot.docs.firstWhere((d) => d['title'] == 'Title 1');
      expect(doc1.id, 'n1');

      final doc2 = snapshot.docs.firstWhere((d) => d['title'] == 'Title 2');
      expect(doc2.id, isNot(''));
    });

    test('getNotifications returns sorted notifications', () async {
      final date1 = DateTime.now().subtract(const Duration(hours: 1));
      final date2 = DateTime.now();

      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'type': 'system',
            'title': 'Old',
            'message': 'Old',
            'createdAt': Timestamp.fromDate(date1),
            'isRead': false,
          });

      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'type': 'system',
            'title': 'New',
            'message': 'New',
            'createdAt': Timestamp.fromDate(date2),
            'isRead': false,
          });

      final notifications = await service.getNotifications();
      expect(notifications.length, 2);
      expect(notifications.first.title, 'New');
      expect(notifications.last.title, 'Old');
    });

    test('getUnreadNotifications returns only unread', () async {
       await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'type': 'system',
            'title': 'Read',
            'message': 'Read',
            'createdAt': Timestamp.now(),
            'isRead': true,
          });
       await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'type': 'system',
            'title': 'Unread',
            'message': 'Unread',
            'createdAt': Timestamp.now(),
            'isRead': false,
          });

       final unread = await service.getUnreadNotifications();
       expect(unread.length, 1);
       expect(unread.first.title, 'Unread');
    });

    test('markAsRead updates isRead field', () async {
      final ref = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'type': 'system',
            'title': 'Test',
            'message': 'Test',
            'createdAt': Timestamp.now(),
            'isRead': false,
          });

      await service.markAsRead(ref.id);

      final snapshot = await ref.get();
      expect(snapshot.data()!['isRead'], true);
    });

    test('markAllAsRead updates all unread notifications', () async {
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'isRead': false,
            'createdAt': Timestamp.now(),
          });
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'isRead': false,
            'createdAt': Timestamp.now(),
          });

      await service.markAllAsRead();

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      expect(snapshot.docs.isEmpty, true);
    });

    test('deleteNotification removes document', () async {
       final ref = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': 'Delete me',
             'createdAt': Timestamp.now(),
          });

       await service.deleteNotification(ref.id);

       final snapshot = await ref.get();
       expect(snapshot.exists, false);
    });

    test('helper methods create notifications correctly', () async {
      await service.createMatchNotification(
        matchedUserName: 'Alice',
        matchedUserId: 'alice_id',
      );

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['type'], 'match');
      expect(data['actionType'], 'open_chat');
      expect(data['actionData'], 'alice_id');
      expect(data['message'], contains('Alice'));
    });
  });
}

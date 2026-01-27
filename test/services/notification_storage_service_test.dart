import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late NotificationStorageService storageService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    storageService = NotificationStorageService(firestore: fakeFirestore);
  });

  final testNotification = NotificationModel(
    id: 'notif1',
    userId: 'user1',
    type: 'system',
    title: 'Test',
    message: 'Hello',
    createdAt: DateTime.now(),
    isRead: false,
  );

  test('saveNotification stores notification in firestore', () async {
    await storageService.saveNotification(testNotification);

    final snapshot = await fakeFirestore.collection('notifications').doc('notif1').get();
    expect(snapshot.exists, true);
    expect(snapshot.data()!['title'], 'Test');
    expect(snapshot.data()!['userId'], 'user1');
  });

  test('getUserNotificationsStream returns notifications for user ordered by date', () async {
    final oldNotification = NotificationModel(
      id: 'notif2',
      userId: 'user1',
      type: 'system',
      title: 'Old',
      message: 'Old Msg',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );

    // Add another user's notification
    final otherUserNotification = NotificationModel(
      id: 'notif3',
      userId: 'user2',
      type: 'system',
      title: 'Other',
      message: 'Other Msg',
      createdAt: DateTime.now(),
    );

    await storageService.saveNotification(oldNotification);
    await storageService.saveNotification(testNotification); // newer
    await storageService.saveNotification(otherUserNotification);

    final stream = storageService.getUserNotificationsStream('user1');

    expect(stream, emits(isA<List<NotificationModel>>()));

    final notifications = await stream.first;
    expect(notifications.length, 2);
    expect(notifications[0].id, 'notif1'); // Newer first
    expect(notifications[1].id, 'notif2');
  });

  test('markAsRead updates isRead field', () async {
    await storageService.saveNotification(testNotification);

    await storageService.markAsRead('notif1');

    final snapshot = await fakeFirestore.collection('notifications').doc('notif1').get();
    expect(snapshot.data()!['isRead'], true);
  });

  test('markAllAsRead updates all user notifications', () async {
     final notif2 = NotificationModel(
      id: 'notif2',
      userId: 'user1',
      type: 'system',
      title: 'Test 2',
      message: 'Hello 2',
      createdAt: DateTime.now(),
      isRead: false,
    );

    // Some already read notification
    final notif3 = NotificationModel(
      id: 'notif3',
      userId: 'user1',
      type: 'system',
      title: 'Test 3',
      message: 'Hello 3',
      createdAt: DateTime.now(),
      isRead: true,
    );

    await storageService.saveNotification(testNotification);
    await storageService.saveNotification(notif2);
    await storageService.saveNotification(notif3);

    await storageService.markAllAsRead('user1');

    final snapshot1 = await fakeFirestore.collection('notifications').doc('notif1').get();
    final snapshot2 = await fakeFirestore.collection('notifications').doc('notif2').get();
    final snapshot3 = await fakeFirestore.collection('notifications').doc('notif3').get();

    expect(snapshot1.data()!['isRead'], true);
    expect(snapshot2.data()!['isRead'], true);
    expect(snapshot3.data()!['isRead'], true);
  });

  test('getUnreadCount returns correct count', () async {
     final notif2 = NotificationModel(
      id: 'notif2',
      userId: 'user1',
      type: 'system',
      title: 'Test 2',
      message: 'Hello 2',
      createdAt: DateTime.now(),
      isRead: true,
    );

    await storageService.saveNotification(testNotification); // isRead default false
    await storageService.saveNotification(notif2);

    final count = await storageService.getUnreadCount('user1');
    expect(count, 1);
  });
}

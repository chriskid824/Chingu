import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationModel', () {
    final now = DateTime.now();
    // Round to milliseconds to avoid precision issues with Timestamp
    final testDate = DateTime.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch);

    final notificationMap = {
      'userId': 'user123',
      'type': 'match',
      'title': 'New Match',
      'message': 'You have a new match!',
      'imageUrl': 'http://example.com/image.jpg',
      'actionType': 'view_profile',
      'actionData': 'user456',
      'deeplink': '/profile/user456',
      'isRead': false,
      'createdAt': Timestamp.fromDate(testDate),
    };

    test('fromMap creates a valid instance', () {
      final notification = NotificationModel.fromMap(notificationMap, 'notification1');

      expect(notification.id, 'notification1');
      expect(notification.userId, 'user123');
      expect(notification.type, 'match');
      expect(notification.title, 'New Match');
      expect(notification.message, 'You have a new match!');
      expect(notification.imageUrl, 'http://example.com/image.jpg');
      expect(notification.actionType, 'view_profile');
      expect(notification.actionData, 'user456');
      expect(notification.deeplink, '/profile/user456');
      expect(notification.isRead, false);
      expect(notification.createdAt, testDate);
    });

    test('toMap returns a valid map', () {
      final notification = NotificationModel(
        id: 'notification1',
        userId: 'user123',
        type: 'match',
        title: 'New Match',
        message: 'You have a new match!',
        imageUrl: 'http://example.com/image.jpg',
        actionType: 'view_profile',
        actionData: 'user456',
        deeplink: '/profile/user456',
        isRead: false,
        createdAt: testDate,
      );

      final map = notification.toMap();

      expect(map['userId'], 'user123');
      expect(map['type'], 'match');
      expect(map['title'], 'New Match');
      expect(map['message'], 'You have a new match!');
      expect(map['imageUrl'], 'http://example.com/image.jpg');
      expect(map['actionType'], 'view_profile');
      expect(map['actionData'], 'user456');
      expect(map['deeplink'], '/profile/user456');
      expect(map['isRead'], false);
      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate(), testDate);
    });

    test('markAsRead returns a new instance with isRead=true', () {
      final notification = NotificationModel(
        id: 'notification1',
        userId: 'user123',
        type: 'match',
        title: 'New Match',
        message: 'You have a new match!',
        createdAt: testDate,
        isRead: false,
        deeplink: '/test',
      );

      final readNotification = notification.markAsRead();

      expect(readNotification.id, notification.id);
      expect(readNotification.isRead, true);
      expect(readNotification.deeplink, '/test'); // Ensure deeplink is preserved
    });

    test('iconName returns correct icon name for type', () {
      expect(NotificationModel(
        id: '1', userId: 'u', type: 'match', title: 't', message: 'm', createdAt: now
      ).iconName, 'favorite');

      expect(NotificationModel(
        id: '1', userId: 'u', type: 'event', title: 't', message: 'm', createdAt: now
      ).iconName, 'event');

      expect(NotificationModel(
        id: '1', userId: 'u', type: 'message', title: 't', message: 'm', createdAt: now
      ).iconName, 'message');

      expect(NotificationModel(
        id: '1', userId: 'u', type: 'rating', title: 't', message: 'm', createdAt: now
      ).iconName, 'star');

      expect(NotificationModel(
        id: '1', userId: 'u', type: 'system', title: 't', message: 'm', createdAt: now
      ).iconName, 'notifications');

      expect(NotificationModel(
        id: '1', userId: 'u', type: 'unknown', title: 't', message: 'm', createdAt: now
      ).iconName, 'notifications');
    });
  });
}

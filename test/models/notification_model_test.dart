import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_app/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    final now = DateTime.now();
    final timestamp = Timestamp.fromDate(now);

    final notificationData = {
      'userId': 'user123',
      'type': 'match',
      'title': 'New Match',
      'message': 'You have a new match!',
      'content': 'You have a new match!', // Should be ignored if message is present, or used as fallback
      'imageUrl': 'http://example.com/image.png',
      'actionType': 'open_chat',
      'actionData': 'chat123',
      'deeplink': '/chat/chat123',
      'isRead': false,
      'createdAt': timestamp,
    };

    test('should create NotificationModel from Map correctly', () {
      final notification = NotificationModel.fromMap(notificationData, 'notification123');

      expect(notification.id, 'notification123');
      expect(notification.userId, 'user123');
      expect(notification.type, 'match');
      expect(notification.title, 'New Match');
      expect(notification.message, 'You have a new match!');
      expect(notification.content, 'You have a new match!');
      expect(notification.imageUrl, 'http://example.com/image.png');
      expect(notification.actionType, 'open_chat');
      expect(notification.actionData, 'chat123');
      expect(notification.deeplink, '/chat/chat123');
      expect(notification.isRead, false);
      expect(notification.createdAt, now); // Note: Precision might be an issue, but mostly okay
    });

    test('should fallback to content if message is missing in fromMap', () {
      final dataWithoutMessage = Map<String, dynamic>.from(notificationData);
      dataWithoutMessage.remove('message');

      final notification = NotificationModel.fromMap(dataWithoutMessage, 'notification123');

      expect(notification.message, 'You have a new match!');
      expect(notification.content, 'You have a new match!');
    });

    test('should convert NotificationModel to Map correctly', () {
      final notification = NotificationModel(
        id: 'notification123',
        userId: 'user123',
        type: 'match',
        title: 'New Match',
        message: 'You have a new match!',
        imageUrl: 'http://example.com/image.png',
        actionType: 'open_chat',
        actionData: 'chat123',
        deeplink: '/chat/chat123',
        isRead: true,
        createdAt: now,
      );

      final map = notification.toMap();

      expect(map['userId'], 'user123');
      expect(map['type'], 'match');
      expect(map['title'], 'New Match');
      expect(map['message'], 'You have a new match!');
      expect(map['content'], 'You have a new match!');
      expect(map['imageUrl'], 'http://example.com/image.png');
      expect(map['actionType'], 'open_chat');
      expect(map['actionData'], 'chat123');
      expect(map['deeplink'], '/chat/chat123');
      expect(map['isRead'], true);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('markAsRead should return a new instance with isRead = true', () {
      final notification = NotificationModel(
        id: 'notification123',
        userId: 'user123',
        type: 'match',
        title: 'New Match',
        message: 'You have a new match!',
        createdAt: now,
      );

      final readNotification = notification.markAsRead();

      expect(readNotification.id, notification.id);
      expect(readNotification.isRead, true);
      // Original should remain unchanged
      expect(notification.isRead, false);
    });

    test('copyWith should update fields correctly', () {
      final notification = NotificationModel(
        id: 'notification123',
        userId: 'user123',
        type: 'match',
        title: 'New Match',
        message: 'You have a new match!',
        createdAt: now,
      );

      final updatedNotification = notification.copyWith(
        title: 'Updated Title',
        deeplink: '/new/link',
      );

      expect(updatedNotification.title, 'Updated Title');
      expect(updatedNotification.deeplink, '/new/link');
      expect(updatedNotification.message, 'You have a new match!');
      expect(updatedNotification.id, 'notification123');
    });
  });
}

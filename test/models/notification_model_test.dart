import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationModel', () {
    final now = DateTime.now();
    final testData = {
      'userId': 'user1',
      'type': 'match',
      'title': 'Test Title',
      'message': 'Test Message',
      'imageUrl': 'http://example.com/image.png',
      'actionType': 'open_chat',
      'actionData': 'chat1',
      'isRead': false,
      'createdAt': Timestamp.fromDate(now),
      'deeplink': '/chat/chat1',
    };

    test('should create NotificationModel from Map correctly', () {
      final notification = NotificationModel.fromMap(testData, '1');

      expect(notification.id, '1');
      expect(notification.userId, 'user1');
      expect(notification.type, 'match');
      expect(notification.title, 'Test Title');
      expect(notification.message, 'Test Message');
      expect(notification.deeplink, '/chat/chat1');
      expect(notification.createdAt, now);
    });

    test('should convert NotificationModel to Map correctly', () {
      final notification = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'match',
        title: 'Test Title',
        message: 'Test Message',
        createdAt: now,
        deeplink: '/chat/chat1',
      );

      final map = notification.toMap();

      expect(map['userId'], 'user1');
      expect(map['type'], 'match');
      expect(map['deeplink'], '/chat/chat1');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('markAsRead should return new instance with isRead true', () {
      final notification = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'match',
        title: 'Test Title',
        message: 'Test Message',
        createdAt: now,
        isRead: false,
        deeplink: '/chat/chat1',
      );

      final readNotification = notification.markAsRead();

      expect(readNotification.id, notification.id);
      expect(readNotification.isRead, true);
      expect(readNotification.deeplink, '/chat/chat1');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationModel', () {
    final timestamp = Timestamp.now();
    final date = timestamp.toDate();

    test('should initialize with correct values including deeplink', () {
      final notification = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        deeplink: 'app://test',
        createdAt: date,
      );

      expect(notification.id, '1');
      expect(notification.userId, 'user1');
      expect(notification.type, 'system');
      expect(notification.title, 'Test Title');
      expect(notification.message, 'Test Message');
      expect(notification.deeplink, 'app://test');
      expect(notification.createdAt, date);
      expect(notification.isRead, false);
    });

    test('fromMap should parse correctly with deeplink', () {
      final map = {
        'userId': 'user1',
        'type': 'system',
        'title': 'Test Title',
        'message': 'Test Message',
        'deeplink': 'app://test',
        'isRead': true,
        'createdAt': timestamp,
      };

      final notification = NotificationModel.fromMap(map, '1');

      expect(notification.id, '1');
      expect(notification.deeplink, 'app://test');
      expect(notification.isRead, true);
    });

    test('toMap should include deeplink', () {
      final notification = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        deeplink: 'app://test',
        createdAt: date,
      );

      final map = notification.toMap();

      expect(map['deeplink'], 'app://test');
      expect(map['userId'], 'user1');
    });

    test('markAsRead should preserve deeplink', () {
      final notification = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        deeplink: 'app://test',
        createdAt: date,
      );

      final readNotification = notification.markAsRead();

      expect(readNotification.isRead, true);
      expect(readNotification.deeplink, 'app://test');
      expect(readNotification.id, notification.id);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    final timestamp = DateTime.now();
    final timestampCloud = Timestamp.fromDate(timestamp);

    test('fromMap creates NotificationModel correctly with deeplink', () {
      final map = {
        'userId': 'user123',
        'type': 'system',
        'title': 'Test Title',
        'message': 'Test Message',
        'deeplink': 'https://example.com',
        'isRead': false,
        'createdAt': timestampCloud,
      };

      final notification = NotificationModel.fromMap(map, 'notif123');

      expect(notification.id, 'notif123');
      expect(notification.deeplink, 'https://example.com');
      expect(notification.createdAt, timestamp);
    });

    test('fromMap creates NotificationModel correctly without deeplink', () {
      final map = {
        'userId': 'user123',
        'type': 'system',
        'title': 'Test Title',
        'message': 'Test Message',
        // deeplink is missing
        'isRead': false,
        'createdAt': timestampCloud,
      };

      final notification = NotificationModel.fromMap(map, 'notif123');

      expect(notification.deeplink, isNull);
    });

    test('toMap includes deeplink', () {
      final notification = NotificationModel(
        id: 'notif123',
        userId: 'user123',
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        deeplink: 'https://example.com',
        createdAt: timestamp,
      );

      final map = notification.toMap();

      expect(map['deeplink'], 'https://example.com');
    });

    test('markAsRead preserves deeplink', () {
      final notification = NotificationModel(
        id: 'notif123',
        userId: 'user123',
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        deeplink: 'https://example.com',
        isRead: false,
        createdAt: timestamp,
      );

      final readNotification = notification.markAsRead();

      expect(readNotification.isRead, true);
      expect(readNotification.deeplink, 'https://example.com');
    });
  });
}

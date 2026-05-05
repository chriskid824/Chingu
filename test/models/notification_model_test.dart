import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../lib/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('should have all required fields including deeplink', () {
      final date = DateTime.now();
      final notification = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'system',
        title: 'Title',
        message: 'Message',
        createdAt: date,
        deeplink: 'myapp://test',
      );

      expect(notification.id, '1');
      expect(notification.userId, 'user1');
      expect(notification.type, 'system');
      expect(notification.title, 'Title');
      expect(notification.message, 'Message');
      expect(notification.createdAt, date);
      expect(notification.deeplink, 'myapp://test');
      expect(notification.isRead, false);
    });

    test('fromMap should parse deeplink', () {
      final date = DateTime.now();
      final map = {
        'userId': 'user1',
        'type': 'system',
        'title': 'Title',
        'message': 'Message',
        'createdAt': Timestamp.fromDate(date),
        'deeplink': 'myapp://test',
        'isRead': true,
      };

      final notification = NotificationModel.fromMap(map, '1');

      expect(notification.deeplink, 'myapp://test');
      expect(notification.isRead, true);
    });

    test('toMap should include deeplink', () {
      final date = DateTime.now();
      final notification = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'system',
        title: 'Title',
        message: 'Message',
        createdAt: date,
        deeplink: 'myapp://test',
      );

      final map = notification.toMap();

      expect(map['deeplink'], 'myapp://test');
    });

    test('markAsRead should preserve deeplink', () {
      final notification = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'system',
        title: 'Title',
        message: 'Message',
        createdAt: DateTime.now(),
        deeplink: 'myapp://test',
      );

      final readNotification = notification.markAsRead();

      expect(readNotification.isRead, true);
      expect(readNotification.deeplink, 'myapp://test');
    });
  });
}

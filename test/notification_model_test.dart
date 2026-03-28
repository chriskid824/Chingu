import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationModel', () {
    test('should instantiate correctly with deeplink', () {
      final now = DateTime.now();
      final notification = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'match',
        title: 'Title',
        message: 'Message',
        deeplink: 'app://test',
        createdAt: now,
      );

      expect(notification.deeplink, 'app://test');
    });

    test('should serialize to map correctly with deeplink', () {
      final now = DateTime.now();
      final notification = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'match',
        title: 'Title',
        message: 'Message',
        deeplink: 'app://test',
        createdAt: now,
      );

      final map = notification.toMap();
      expect(map['deeplink'], 'app://test');
      expect(map['title'], 'Title');
    });

    test('should deserialize from map correctly with deeplink', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      final map = {
        'userId': 'user1',
        'type': 'match',
        'title': 'Title',
        'message': 'Message',
        'deeplink': 'app://test',
        'isRead': false,
        'createdAt': timestamp,
      };

      final notification = NotificationModel.fromMap(map, '1');
      expect(notification.deeplink, 'app://test');
      expect(notification.id, '1');
    });

    test('markAsRead should preserve deeplink', () {
      final now = DateTime.now();
      final notification = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'match',
        title: 'Title',
        message: 'Message',
        deeplink: 'app://test',
        isRead: false,
        createdAt: now,
      );

      final readNotification = notification.markAsRead();
      expect(readNotification.isRead, true);
      expect(readNotification.deeplink, 'app://test');
    });
  });
}

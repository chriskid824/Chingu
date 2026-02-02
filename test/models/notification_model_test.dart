import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationModel', () {
    test('should instantiate correctly', () {
      final notification = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        deeplink: 'app://test',
        createdAt: DateTime.now(),
      );

      expect(notification.id, '1');
      expect(notification.userId, 'user1');
      expect(notification.type, 'system');
      expect(notification.title, 'Test Title');
      expect(notification.message, 'Test Message');
      expect(notification.deeplink, 'app://test');
      expect(notification.isRead, false);
    });

    test('toMap should return correct map with deeplink', () {
      final date = DateTime.now();
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

      expect(map['userId'], 'user1');
      expect(map['type'], 'system');
      expect(map['title'], 'Test Title');
      expect(map['message'], 'Test Message');
      expect(map['deeplink'], 'app://test');
      expect(map['isRead'], false);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('fromMap should create model correctly with deeplink', () {
      final date = DateTime.now();
      final map = {
        'userId': 'user1',
        'type': 'system',
        'title': 'Test Title',
        'message': 'Test Message',
        'deeplink': 'app://test',
        'isRead': true,
        'createdAt': Timestamp.fromDate(date),
      };

      final notification = NotificationModel.fromMap(map, '1');

      expect(notification.id, '1');
      expect(notification.userId, 'user1');
      expect(notification.type, 'system');
      expect(notification.title, 'Test Title');
      expect(notification.message, 'Test Message');
      expect(notification.deeplink, 'app://test');
      expect(notification.isRead, true);
      expect(notification.createdAt.isAtSameMomentAs(date), true);
    });

    test('markAsRead should preserve deeplink', () {
      final notification = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        deeplink: 'app://test',
        createdAt: DateTime.now(),
        isRead: false,
      );

      final readNotification = notification.markAsRead();

      expect(readNotification.isRead, true);
      expect(readNotification.deeplink, 'app://test');
      expect(readNotification.id, notification.id);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('should create NotificationModel from map with deeplink', () {
      final date = DateTime.now();
      final map = {
        'userId': 'user1',
        'type': 'system',
        'title': 'Test Title',
        'message': 'Test Message',
        'imageUrl': 'http://example.com/image.png',
        'actionType': 'navigate',
        'actionData': '123',
        'deeplink': 'app://test/deeplink',
        'isRead': false,
        'createdAt': Timestamp.fromDate(date),
      };

      final notification = NotificationModel.fromMap(map, 'id1');

      expect(notification.id, 'id1');
      expect(notification.userId, 'user1');
      expect(notification.type, 'system');
      expect(notification.title, 'Test Title');
      expect(notification.message, 'Test Message');
      expect(notification.imageUrl, 'http://example.com/image.png');
      expect(notification.actionType, 'navigate');
      expect(notification.actionData, '123');
      expect(notification.deeplink, 'app://test/deeplink');
      expect(notification.isRead, false);
      expect(notification.createdAt, date);
    });

    test('should convert NotificationModel to map including deeplink', () {
      final date = DateTime.now();
      final notification = NotificationModel(
        id: 'id1',
        userId: 'user1',
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        deeplink: 'app://test/deeplink',
        createdAt: date,
      );

      final map = notification.toMap();

      expect(map['userId'], 'user1');
      expect(map['title'], 'Test Title');
      expect(map['deeplink'], 'app://test/deeplink');
    });
  });
}

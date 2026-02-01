import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationModel', () {
    final now = DateTime.now();

    test('should create NotificationModel with deeplink', () {
      final model = NotificationModel(
        id: '123',
        userId: 'user_1',
        type: 'match',
        title: 'New Match',
        message: 'You have a new match!',
        createdAt: now,
        deeplink: '/chat/123',
      );

      expect(model.id, '123');
      expect(model.userId, 'user_1');
      expect(model.type, 'match');
      expect(model.title, 'New Match');
      expect(model.message, 'You have a new match!');
      expect(model.createdAt, now);
      expect(model.deeplink, '/chat/123');
      expect(model.isRead, false);
    });

    test('should convert to Map correctly including deeplink', () {
      final model = NotificationModel(
        id: '123',
        userId: 'user_1',
        type: 'event',
        title: 'Event Reminder',
        message: 'Dinner is soon',
        createdAt: now,
        deeplink: '/event/456',
        isRead: true,
      );

      final map = model.toMap();

      expect(map['userId'], 'user_1');
      expect(map['type'], 'event');
      expect(map['title'], 'Event Reminder');
      expect(map['message'], 'Dinner is soon');
      expect(map['deeplink'], '/event/456');
      expect(map['isRead'], true);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('should create from Map correctly including deeplink', () {
      final map = {
        'userId': 'user_1',
        'type': 'system',
        'title': 'System Update',
        'message': 'Update available',
        'createdAt': Timestamp.fromDate(now),
        'deeplink': '/settings',
        'isRead': false,
      };

      final model = NotificationModel.fromMap(map, '789');

      expect(model.id, '789');
      expect(model.userId, 'user_1');
      expect(model.type, 'system');
      expect(model.title, 'System Update');
      expect(model.message, 'Update available');
      expect(model.createdAt, now);
      expect(model.deeplink, '/settings');
      expect(model.isRead, false);
    });

    test('markAsRead should preserve deeplink', () {
      final model = NotificationModel(
        id: '123',
        userId: 'user_1',
        type: 'match',
        title: 'Title',
        message: 'Message',
        createdAt: now,
        deeplink: '/chat/123',
      );

      final readModel = model.markAsRead();

      expect(readModel.isRead, true);
      expect(readModel.deeplink, '/chat/123');
      expect(readModel.id, model.id);
    });
  });
}

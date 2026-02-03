import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationModel', () {
    final DateTime now = DateTime.now();
    // Round to microseconds to match Timestamp precision if needed,
    // but typically we accept slight differences or use Timestamp in the map.
    // For simplicity, we'll use a fixed time.
    final DateTime fixedTime = DateTime(2023, 1, 1, 12, 0, 0);
    final Timestamp fixedTimestamp = Timestamp.fromDate(fixedTime);

    test('should create NotificationModel from constructor', () {
      final model = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'match',
        title: 'New Match',
        message: 'You have a match!',
        createdAt: fixedTime,
        deeplink: '/matches/123',
      );

      expect(model.id, '1');
      expect(model.userId, 'user1');
      expect(model.type, 'match');
      expect(model.title, 'New Match');
      expect(model.message, 'You have a match!');
      expect(model.createdAt, fixedTime);
      expect(model.deeplink, '/matches/123');
      expect(model.isRead, false);
    });

    test('fromMap should create valid model', () {
      final map = {
        'userId': 'user1',
        'type': 'event',
        'title': 'Event Reminder',
        'message': 'Dinner is soon',
        'createdAt': fixedTimestamp,
        'deeplink': '/events/456',
        'isRead': true,
        'actionType': 'navigate',
        'actionData': '{"id": "456"}',
      };

      final model = NotificationModel.fromMap(map, '2');

      expect(model.id, '2');
      expect(model.userId, 'user1');
      expect(model.type, 'event');
      expect(model.title, 'Event Reminder');
      expect(model.message, 'Dinner is soon');
      expect(model.createdAt, fixedTime);
      expect(model.deeplink, '/events/456');
      expect(model.isRead, true);
      expect(model.actionType, 'navigate');
      expect(model.actionData, '{"id": "456"}');
    });

    test('toMap should return valid map', () {
      final model = NotificationModel(
        id: '3',
        userId: 'user2',
        type: 'message',
        title: 'New Message',
        message: 'Hello',
        createdAt: fixedTime,
        deeplink: '/chat/789',
        isRead: false,
      );

      final map = model.toMap();

      expect(map['userId'], 'user2');
      expect(map['type'], 'message');
      expect(map['title'], 'New Message');
      expect(map['message'], 'Hello');
      expect(map['createdAt'], fixedTimestamp);
      expect(map['deeplink'], '/chat/789');
      expect(map['isRead'], false);
    });

    test('markAsRead should return new instance with isRead = true', () {
      final model = NotificationModel(
        id: '4',
        userId: 'user3',
        type: 'system',
        title: 'System Update',
        message: 'Update available',
        createdAt: fixedTime,
        deeplink: '/settings',
        isRead: false,
      );

      final newModel = model.markAsRead();

      expect(newModel.id, model.id);
      expect(newModel.isRead, true);
      expect(newModel.deeplink, '/settings'); // Ensure deeplink is preserved
      expect(newModel.type, 'system');
    });

    test('iconName should return correct icon name for types', () {
      expect(NotificationModel(id: '1', userId: 'u', type: 'match', title: 't', message: 'm', createdAt: now).iconName, 'favorite');
      expect(NotificationModel(id: '1', userId: 'u', type: 'event', title: 't', message: 'm', createdAt: now).iconName, 'event');
      expect(NotificationModel(id: '1', userId: 'u', type: 'message', title: 't', message: 'm', createdAt: now).iconName, 'message');
      expect(NotificationModel(id: '1', userId: 'u', type: 'rating', title: 't', message: 'm', createdAt: now).iconName, 'star');
      expect(NotificationModel(id: '1', userId: 'u', type: 'system', title: 't', message: 'm', createdAt: now).iconName, 'notifications');
      expect(NotificationModel(id: '1', userId: 'u', type: 'unknown', title: 't', message: 'm', createdAt: now).iconName, 'notifications');
    });
  });
}

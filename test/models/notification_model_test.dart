import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    final now = DateTime.now();
    // Round to microseconds to match Timestamp precision loss if any,
    // though Timestamp stores seconds and nanoseconds.
    final timestamp = Timestamp.fromDate(now);

    final notificationData = {
      'userId': 'user_123',
      'type': 'match',
      'title': 'New Match!',
      'message': 'You have a new match with Alice',
      'imageUrl': 'http://example.com/image.jpg',
      'actionType': 'open_chat',
      'actionData': 'chat_456',
      'isRead': false,
      'createdAt': timestamp,
    };

    test('fromMap creates a valid NotificationModel', () {
      final model = NotificationModel.fromMap(notificationData, 'notif_001');

      expect(model.id, 'notif_001');
      expect(model.userId, 'user_123');
      expect(model.type, 'match');
      expect(model.title, 'New Match!');
      expect(model.message, 'You have a new match with Alice');
      expect(model.imageUrl, 'http://example.com/image.jpg');
      expect(model.actionType, 'open_chat');
      expect(model.actionData, 'chat_456');
      expect(model.isRead, false);
      // Compare milliseconds to avoid minor precision issues
      expect(model.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('toMap creates a valid map', () {
      final model = NotificationModel(
        id: 'notif_001',
        userId: 'user_123',
        type: 'event',
        title: 'Event Reminder',
        message: 'Dinner starts in 1 hour',
        createdAt: now,
        isRead: true,
      );

      final map = model.toMap();

      expect(map['userId'], 'user_123');
      expect(map['type'], 'event');
      expect(map['title'], 'Event Reminder');
      expect(map['message'], 'Dinner starts in 1 hour');
      expect(map['isRead'], true);
      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate().millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('markAsRead returns a new instance with isRead = true', () {
      final model = NotificationModel(
        id: 'notif_001',
        userId: 'user_123',
        type: 'match',
        title: 'Title',
        message: 'Message',
        createdAt: now,
        isRead: false,
      );

      final readModel = model.markAsRead();

      expect(readModel.id, model.id);
      expect(readModel.isRead, true);
      expect(model.isRead, false); // Original should remain unchanged
    });

    test('get iconName returns correct icon for types', () {
      final base = NotificationModel(
        id: '1', userId: '1', type: 'match', title: '', message: '', createdAt: now,
      );

      expect(NotificationModel(id: '1', userId: '1', type: 'match', title: '', message: '', createdAt: now).iconName, 'favorite');
      expect(NotificationModel(id: '1', userId: '1', type: 'event', title: '', message: '', createdAt: now).iconName, 'event');
      expect(NotificationModel(id: '1', userId: '1', type: 'message', title: '', message: '', createdAt: now).iconName, 'message');
      expect(NotificationModel(id: '1', userId: '1', type: 'rating', title: '', message: '', createdAt: now).iconName, 'star');
      expect(NotificationModel(id: '1', userId: '1', type: 'system', title: '', message: '', createdAt: now).iconName, 'notifications');
      expect(NotificationModel(id: '1', userId: '1', type: 'unknown', title: '', message: '', createdAt: now).iconName, 'notifications');
    });
  });
}

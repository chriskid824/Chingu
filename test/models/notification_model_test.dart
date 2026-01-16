import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    // Note: Timestamp in tests without actual Firebase might behave slightly differently,
    // but usually in unit tests we can use it if cloud_firestore is imported.
    // If not, we might need to mock Timestamp or use DateTime directly if strict typing allows.
    // NotificationModel expects Timestamp in fromMap/toMap.

    // We create a mock timestamp
    final now = DateTime.now();
    final timestamp = Timestamp.fromDate(now);

    test('should instantiate correctly', () {
      final model = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'match',
        title: 'New Match',
        message: 'You have a new match!',
        createdAt: now,
        deeplink: '/matches/123',
      );

      expect(model.id, '1');
      expect(model.userId, 'user1');
      expect(model.type, 'match');
      expect(model.title, 'New Match');
      expect(model.message, 'You have a new match!');
      expect(model.content, 'You have a new match!');
      expect(model.createdAt, now);
      expect(model.deeplink, '/matches/123');
      expect(model.isRead, false);
    });

    test('fromMap should parse correctly', () {
      final map = {
        'userId': 'user1',
        'type': 'event',
        'title': 'Event Update',
        'message': 'Event details changed',
        'createdAt': timestamp,
        'deeplink': '/events/456',
        'isRead': true,
      };

      final model = NotificationModel.fromMap(map, '2');

      expect(model.id, '2');
      expect(model.userId, 'user1');
      expect(model.type, 'event');
      expect(model.title, 'Event Update');
      expect(model.message, 'Event details changed');
      expect(model.content, 'Event details changed');
      expect(model.createdAt, now); // Might need tolerance or precise match
      expect(model.deeplink, '/events/456');
      expect(model.isRead, true);
    });

    test('toMap should serialize correctly', () {
      final model = NotificationModel(
        id: '3',
        userId: 'user2',
        type: 'message',
        title: 'New Message',
        message: 'Hello',
        createdAt: now,
        deeplink: '/chat/789',
        isRead: false,
      );

      final map = model.toMap();

      expect(map['userId'], 'user2');
      expect(map['type'], 'message');
      expect(map['title'], 'New Message');
      expect(map['message'], 'Hello');
      expect(map['createdAt'], timestamp);
      expect(map['deeplink'], '/chat/789');
      expect(map['isRead'], false);
    });

    test('markAsRead should set isRead to true and preserve other fields', () {
      final model = NotificationModel(
        id: '4',
        userId: 'user3',
        type: 'system',
        title: 'System Alert',
        message: 'Maintenance soon',
        createdAt: now,
        deeplink: '/system',
        isRead: false,
      );

      final readModel = model.markAsRead();

      expect(readModel.id, model.id);
      expect(readModel.userId, model.userId);
      expect(readModel.type, model.type);
      expect(readModel.title, model.title);
      expect(readModel.message, model.message);
      expect(readModel.createdAt, model.createdAt);
      expect(readModel.deeplink, model.deeplink);
      expect(readModel.isRead, true);
    });
  });
}

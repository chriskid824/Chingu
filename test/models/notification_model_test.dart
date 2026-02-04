import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationModel', () {
    test('should parse from map with backward compatibility (message -> content)', () {
      final map = {
        'userId': 'user1',
        'type': 'match',
        'title': 'New Match',
        'message': 'You have a new match',
        'createdAt': Timestamp.now(),
      };

      final notification = NotificationModel.fromMap(map, 'id1');

      expect(notification.id, 'id1');
      expect(notification.userId, 'user1');
      expect(notification.type, NotificationType.match);
      expect(notification.title, 'New Match');
      expect(notification.content, 'You have a new match');
      expect(notification.deeplink, isNull);
    });

    test('should parse from map with new fields (content, deeplink)', () {
      final map = {
        'userId': 'user1',
        'type': 'event',
        'title': 'New Event',
        'content': 'Event details here',
        'deeplink': 'app://event/123',
        'createdAt': Timestamp.now(),
      };

      final notification = NotificationModel.fromMap(map, 'id2');

      expect(notification.type, NotificationType.event);
      expect(notification.content, 'Event details here');
      expect(notification.deeplink, 'app://event/123');
    });

    test('should default unknown type to system', () {
      final map = {
        'userId': 'user1',
        'type': 'unknown_type',
        'title': 'Title',
        'content': 'Content',
        'createdAt': Timestamp.now(),
      };

      final notification = NotificationModel.fromMap(map, 'id3');

      expect(notification.type, NotificationType.system);
    });

    test('should serialize to map correctly', () {
      final now = DateTime.now();
      final notification = NotificationModel(
        id: 'id4',
        userId: 'user1',
        type: NotificationType.message,
        title: 'Title',
        content: 'Content',
        deeplink: 'app://chat/1',
        createdAt: now,
      );

      final map = notification.toMap();

      expect(map['userId'], 'user1');
      expect(map['type'], 'message');
      expect(map['title'], 'Title');
      expect(map['content'], 'Content');
      expect(map['deeplink'], 'app://chat/1');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('markAsRead should return new instance with isRead = true', () {
      final notification = NotificationModel(
        id: 'id5',
        userId: 'user1',
        type: NotificationType.system,
        title: 'Title',
        content: 'Content',
        createdAt: DateTime.now(),
        isRead: false,
      );

      final readNotification = notification.markAsRead();

      expect(readNotification.id, notification.id);
      expect(readNotification.isRead, true);
      expect(notification.isRead, false); // Original should stay unchanged
    });
  });
}

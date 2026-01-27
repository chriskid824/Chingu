import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationModel', () {
    test('should create instance from map with deeplink', () {
      final date = DateTime.now();
      // Ensure we truncate microsecond precision as Firestore Timestamps might lose it or behave differently
      // But for local test using Timestamp.fromDate, it should be fine.
      final map = {
        'userId': 'user1',
        'type': 'match',
        'title': 'Test Title',
        'message': 'Test Message',
        'deeplink': '/chat/123',
        'isRead': false,
        'createdAt': Timestamp.fromDate(date),
      };

      final model = NotificationModel.fromMap(map, 'id1');

      expect(model.id, 'id1');
      expect(model.userId, 'user1');
      expect(model.deeplink, '/chat/123');
      expect(model.type, 'match');
    });

    test('should serialize to map with deeplink', () {
      final date = DateTime.now();
      final model = NotificationModel(
        id: 'id1',
        userId: 'user1',
        type: 'event',
        title: 'Event Title',
        message: 'Event Message',
        deeplink: '/event/456',
        createdAt: date,
      );

      final map = model.toMap();

      expect(map['deeplink'], '/event/456');
      expect(map['type'], 'event');
    });

    test('markAsRead should preserve deeplink', () {
      final date = DateTime.now();
      final model = NotificationModel(
        id: 'id1',
        userId: 'user1',
        type: 'match',
        title: 'Title',
        message: 'Message',
        deeplink: '/chat/789',
        createdAt: date,
        isRead: false,
      );

      final readModel = model.markAsRead();

      expect(readModel.isRead, true);
      expect(readModel.deeplink, '/chat/789');
      expect(readModel.id, model.id);
    });
  });
}

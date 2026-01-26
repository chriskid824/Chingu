import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationModel', () {
    final timestamp = DateTime.now();
    // Round to milliseconds to avoid precision issues with Timestamp conversion
    final roundedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);

    final notification = NotificationModel(
      id: 'test_id',
      userId: 'user_1',
      type: 'system',
      title: 'Test Title',
      content: 'Test Content',
      timestamp: roundedTimestamp,
      deeplink: '/test',
      isRead: false,
    );

    test('toMap returns correct map', () {
      final map = notification.toMap();
      expect(map['userId'], 'user_1');
      expect(map['type'], 'system');
      expect(map['title'], 'Test Title');
      expect(map['content'], 'Test Content');
      expect(map['timestamp'], isA<Timestamp>());
      expect(map['deeplink'], '/test');
      expect(map['isRead'], false);
    });

    test('fromMap creates correct object', () {
      final map = {
        'userId': 'user_1',
        'type': 'system',
        'title': 'Test Title',
        'content': 'Test Content',
        'timestamp': Timestamp.fromDate(roundedTimestamp),
        'deeplink': '/test',
        'isRead': false,
      };

      final newNotification = NotificationModel.fromMap(map, 'test_id');
      expect(newNotification.id, 'test_id');
      expect(newNotification.userId, 'user_1');
      expect(newNotification.type, 'system');
      expect(newNotification.title, 'Test Title');
      expect(newNotification.content, 'Test Content');
      expect(newNotification.timestamp, roundedTimestamp);
      expect(newNotification.deeplink, '/test');
      expect(newNotification.isRead, false);
    });

    test('markAsRead returns new instance with isRead true', () {
      final readNotification = notification.markAsRead();
      expect(readNotification.id, notification.id);
      expect(readNotification.isRead, true);
    });
  });
}

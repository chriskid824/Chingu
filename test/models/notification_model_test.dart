import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationModel', () {
    final now = DateTime.now();
    // Round to milliseconds to avoid precision issues with Firestore timestamps
    final timestamp = DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second, now.millisecond);

    final notificationData = {
      'userId': 'user123',
      'type': 'match',
      'title': 'Test Title',
      'message': 'Test Message',
      'imageUrl': 'http://example.com/image.jpg',
      'actionType': 'navigate',
      'actionData': 'match123',
      'deeplink': 'app://match/123',
      'isRead': false,
      'createdAt': Timestamp.fromDate(timestamp),
    };

    test('should create model from map correctly', () {
      final model = NotificationModel.fromMap(notificationData, 'notif123');

      expect(model.id, 'notif123');
      expect(model.userId, 'user123');
      expect(model.type, 'match');
      expect(model.title, 'Test Title');
      expect(model.message, 'Test Message');
      expect(model.imageUrl, 'http://example.com/image.jpg');
      expect(model.actionType, 'navigate');
      expect(model.actionData, 'match123');
      expect(model.deeplink, 'app://match/123');
      expect(model.isRead, false);
      expect(model.createdAt, timestamp);
    });

    test('should convert model to map correctly', () {
      final model = NotificationModel(
        id: 'notif123',
        userId: 'user123',
        type: 'match',
        title: 'Test Title',
        message: 'Test Message',
        imageUrl: 'http://example.com/image.jpg',
        actionType: 'navigate',
        actionData: 'match123',
        deeplink: 'app://match/123',
        isRead: false,
        createdAt: timestamp,
      );

      final map = model.toMap();

      expect(map['userId'], 'user123');
      expect(map['type'], 'match');
      expect(map['title'], 'Test Title');
      expect(map['message'], 'Test Message');
      expect(map['imageUrl'], 'http://example.com/image.jpg');
      expect(map['actionType'], 'navigate');
      expect(map['actionData'], 'match123');
      expect(map['deeplink'], 'app://match/123');
      expect(map['isRead'], false);
      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate(), timestamp);
    });

    test('markAsRead should return new instance with isRead = true', () {
      final model = NotificationModel(
        id: 'notif123',
        userId: 'user123',
        type: 'match',
        title: 'Test Title',
        message: 'Test Message',
        deeplink: 'app://match/123',
        createdAt: timestamp,
      );

      final readModel = model.markAsRead();

      expect(readModel.id, model.id);
      expect(readModel.isRead, true);
      expect(readModel.deeplink, model.deeplink);
    });

    test('iconName should return correct icon for types', () {
      final matchNotif = NotificationModel(
        id: '1',
        userId: 'u',
        type: 'match',
        title: 't',
        message: 'm',
        createdAt: timestamp,
      );
      expect(matchNotif.iconName, 'favorite');

      final eventNotif = NotificationModel(
        id: '1',
        userId: 'u',
        type: 'event',
        title: 't',
        message: 'm',
        createdAt: timestamp,
      );
      expect(eventNotif.iconName, 'event');

      final unknownNotif = NotificationModel(
        id: '1',
        userId: 'u',
        type: 'unknown',
        title: 't',
        message: 'm',
        createdAt: timestamp,
      );
      expect(unknownNotif.iconName, 'notifications');
    });
  });
}

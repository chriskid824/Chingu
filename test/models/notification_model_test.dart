import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:love_app/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    final now = DateTime.now();
    // Round to microseconds to match Timestamp precision usually handled in tests or Firestore
    // However, here we just want to ensure it survives the round trip or conversion.
    // Simulating Timestamp behavior for fromMap.
    final timestamp = Timestamp.fromDate(now);

    final notificationData = {
      'userId': 'user123',
      'type': 'match',
      'title': 'New Match',
      'message': 'You have a new match!',
      'imageUrl': 'http://example.com/image.jpg',
      'actionType': 'navigate',
      'actionData': '{"id": "match123"}',
      'deeplink': '/match/match123',
      'isRead': false,
      'createdAt': timestamp,
    };

    test('should create NotificationModel from Map', () {
      final model = NotificationModel.fromMap(notificationData, 'notif123');

      expect(model.id, 'notif123');
      expect(model.userId, 'user123');
      expect(model.type, 'match');
      expect(model.title, 'New Match');
      expect(model.message, 'You have a new match!');
      expect(model.imageUrl, 'http://example.com/image.jpg');
      expect(model.actionType, 'navigate');
      expect(model.actionData, '{"id": "match123"}');
      expect(model.deeplink, '/match/match123');
      expect(model.isRead, false);
      expect(model.createdAt, now);
    });

    test('should convert NotificationModel to Map', () {
      final model = NotificationModel(
        id: 'notif123',
        userId: 'user123',
        type: 'match',
        title: 'New Match',
        message: 'You have a new match!',
        imageUrl: 'http://example.com/image.jpg',
        actionType: 'navigate',
        actionData: '{"id": "match123"}',
        deeplink: '/match/match123',
        isRead: false,
        createdAt: now,
      );

      final map = model.toMap();

      expect(map['userId'], 'user123');
      expect(map['type'], 'match');
      expect(map['title'], 'New Match');
      expect(map['message'], 'You have a new match!');
      expect(map['imageUrl'], 'http://example.com/image.jpg');
      expect(map['actionType'], 'navigate');
      expect(map['actionData'], '{"id": "match123"}');
      expect(map['deeplink'], '/match/match123');
      expect(map['isRead'], false);
      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate(), now);
    });

    test('markAsRead should return a new instance with isRead=true and same properties', () {
      final model = NotificationModel(
        id: 'notif123',
        userId: 'user123',
        type: 'match',
        title: 'New Match',
        message: 'You have a new match!',
        imageUrl: 'http://example.com/image.jpg',
        actionType: 'navigate',
        actionData: '{"id": "match123"}',
        deeplink: '/match/match123',
        isRead: false,
        createdAt: now,
      );

      final readModel = model.markAsRead();

      expect(readModel.id, model.id);
      expect(readModel.userId, model.userId);
      expect(readModel.type, model.type);
      expect(readModel.title, model.title);
      expect(readModel.message, model.message);
      expect(readModel.imageUrl, model.imageUrl);
      expect(readModel.actionType, model.actionType);
      expect(readModel.actionData, model.actionData);
      expect(readModel.deeplink, model.deeplink);
      expect(readModel.isRead, true);
      expect(readModel.createdAt, model.createdAt);
    });

    test('iconName should return correct icon name for each type', () {
      final baseModel = NotificationModel(
        id: 'id', userId: 'uid', type: 'system', title: 't', message: 'm', createdAt: now
      );

      expect(NotificationModel(id: '1', userId: 'u', type: 'match', title: 't', message: 'm', createdAt: now).iconName, 'favorite');
      expect(NotificationModel(id: '1', userId: 'u', type: 'event', title: 't', message: 'm', createdAt: now).iconName, 'event');
      expect(NotificationModel(id: '1', userId: 'u', type: 'message', title: 't', message: 'm', createdAt: now).iconName, 'message');
      expect(NotificationModel(id: '1', userId: 'u', type: 'rating', title: 't', message: 'm', createdAt: now).iconName, 'star');
      expect(NotificationModel(id: '1', userId: 'u', type: 'system', title: 't', message: 'm', createdAt: now).iconName, 'notifications');
      expect(NotificationModel(id: '1', userId: 'u', type: 'unknown', title: 't', message: 'm', createdAt: now).iconName, 'notifications');
    });
  });
}

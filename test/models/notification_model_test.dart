import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationModel', () {
    final now = DateTime.now();
    final notification = NotificationModel(
      id: '123',
      userId: 'user1',
      type: 'match',
      title: 'Title',
      message: 'Message',
      imageUrl: 'http://image.com',
      deeplink: 'app://deeplink',
      actionType: 'navigate',
      actionData: 'data',
      isRead: true,
      createdAt: now,
    );

    test('should serialize to map correctly', () {
      final map = notification.toMap();
      expect(map['userId'], 'user1');
      expect(map['deeplink'], 'app://deeplink');
      expect(map['actionType'], 'navigate');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('should deserialize from map correctly', () {
      final map = {
        'userId': 'user1',
        'type': 'match',
        'title': 'Title',
        'message': 'Message',
        'imageUrl': 'http://image.com',
        'deeplink': 'app://deeplink',
        'actionType': 'navigate',
        'actionData': 'data',
        'isRead': true,
        'createdAt': Timestamp.fromDate(now),
      };

      final result = NotificationModel.fromMap(map, '123');
      expect(result.id, '123');
      expect(result.deeplink, 'app://deeplink');
      expect(result.actionType, 'navigate');
      // Compare time roughly or exact depending on precision, but here we just check it is not null
      expect(result.createdAt.difference(now).inSeconds, 0);
    });

    test('copyWith should work correctly', () {
      final updated = notification.copyWith(deeplink: 'app://new');
      expect(updated.deeplink, 'app://new');
      expect(updated.id, notification.id);
    });
  });
}

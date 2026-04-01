import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationModel', () {
    final date = DateTime(2023, 1, 1);
    final timestamp = Timestamp.fromDate(date);

    test('should create from map with deeplink', () {
      final map = {
        'userId': 'user123',
        'type': 'system',
        'title': 'Test Title',
        'message': 'Test Message',
        'deeplink': 'https://example.com',
        'isRead': false,
        'createdAt': timestamp,
      };

      final model = NotificationModel.fromMap(map, 'notification123');

      expect(model.id, 'notification123');
      expect(model.userId, 'user123');
      expect(model.type, 'system');
      expect(model.title, 'Test Title');
      expect(model.message, 'Test Message');
      expect(model.deeplink, 'https://example.com');
      expect(model.isRead, false);
      expect(model.createdAt, date);
    });

    test('should convert to map with deeplink', () {
      final model = NotificationModel(
        id: 'notification123',
        userId: 'user123',
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        deeplink: 'https://example.com',
        createdAt: date,
      );

      final map = model.toMap();

      expect(map['userId'], 'user123');
      expect(map['type'], 'system');
      expect(map['title'], 'Test Title');
      expect(map['message'], 'Test Message');
      expect(map['deeplink'], 'https://example.com');
      expect(map['isRead'], false);
      expect(map['createdAt'], timestamp);
    });

    test('markAsRead should preserve deeplink', () {
      final model = NotificationModel(
        id: 'notification123',
        userId: 'user123',
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
        deeplink: 'https://example.com',
        createdAt: date,
      );

      final readModel = model.markAsRead();

      expect(readModel.isRead, true);
      expect(readModel.deeplink, 'https://example.com');
    });

    test('should handle null deeplink', () {
      final map = {
        'userId': 'user123',
        'type': 'system',
        'title': 'Test Title',
        'message': 'Test Message',
        'createdAt': timestamp,
      };

      final model = NotificationModel.fromMap(map, 'notification123');

      expect(model.deeplink, null);

      final newMap = model.toMap();
      expect(newMap['deeplink'], null);
    });
  });
}

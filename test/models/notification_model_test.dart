import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationModel', () {
    test('should create from constructor', () {
      final now = DateTime.now();
      final model = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'system',
        title: 'Title',
        content: 'Content',
        deeplink: 'app://test',
        createdAt: now,
      );

      expect(model.content, 'Content');
      expect(model.deeplink, 'app://test');
    });

    test('should map from Map', () {
      final now = Timestamp.now();
      final map = {
        'userId': 'user1',
        'type': 'system',
        'title': 'Title',
        'content': 'Content',
        'deeplink': 'app://test',
        'createdAt': now,
      };

      final model = NotificationModel.fromMap(map, '1');
      expect(model.content, 'Content');
      expect(model.deeplink, 'app://test');
      expect(model.createdAt, now.toDate());
    });

    test('should map from Map with fallback message', () {
      final now = Timestamp.now();
      final map = {
        'userId': 'user1',
        'type': 'system',
        'title': 'Title',
        'message': 'Old Content',
        'createdAt': now,
      };

      final model = NotificationModel.fromMap(map, '1');
      expect(model.content, 'Old Content');
    });

    test('should toMap correctly', () {
      final now = DateTime.now();
      final model = NotificationModel(
        id: '1',
        userId: 'user1',
        type: 'system',
        title: 'Title',
        content: 'Content',
        deeplink: 'app://test',
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['content'], 'Content');
      expect(map['deeplink'], 'app://test');
      // Timestamp equality might be tricky, checking instance
      expect(map['createdAt'], isA<Timestamp>());
    });
  });
}

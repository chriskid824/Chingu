import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('should create model from map with content', () {
      final map = {
        'userId': 'user1',
        'type': 'system',
        'title': 'Test Title',
        'content': 'Test Content',
        'isRead': false,
        'createdAt': Timestamp.now(),
      };

      final model = NotificationModel.fromMap(map, '123');

      expect(model.id, '123');
      expect(model.content, 'Test Content');
      expect(model.deeplink, null);
    });

    test('should create model from map with message (legacy)', () {
      final map = {
        'userId': 'user1',
        'type': 'system',
        'title': 'Test Title',
        'message': 'Legacy Message',
        'isRead': false,
        'createdAt': Timestamp.now(),
      };

      final model = NotificationModel.fromMap(map, '123');

      expect(model.content, 'Legacy Message');
    });

    test('should prioritize content over message', () {
      final map = {
        'userId': 'user1',
        'type': 'system',
        'title': 'Test Title',
        'content': 'New Content',
        'message': 'Legacy Message',
        'isRead': false,
        'createdAt': Timestamp.now(),
      };

      final model = NotificationModel.fromMap(map, '123');

      expect(model.content, 'New Content');
    });

    test('should include deeplink', () {
       final map = {
        'userId': 'user1',
        'type': 'system',
        'title': 'Test Title',
        'content': 'Test Content',
        'deeplink': 'app://test',
        'isRead': false,
        'createdAt': Timestamp.now(),
      };

      final model = NotificationModel.fromMap(map, '123');

      expect(model.deeplink, 'app://test');
    });

    test('toMap should include both content and message', () {
      final model = NotificationModel(
        id: '123',
        userId: 'user1',
        type: 'system',
        title: 'Title',
        content: 'Content',
        createdAt: DateTime.now(),
      );

      final map = model.toMap();

      expect(map['content'], 'Content');
      expect(map['message'], 'Content');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('should create from map with content', () {
      final map = {
        'userId': 'user1',
        'type': 'match',
        'title': 'Match!',
        'content': 'You have a match',
        'createdAt': Timestamp.now(),
        'isRead': false,
      };

      final model = NotificationModel.fromMap(map, 'id1');
      expect(model.content, 'You have a match');
      expect(model.id, 'id1');
    });

    test('should create from map with message (backward compatibility)', () {
      final map = {
        'userId': 'user1',
        'type': 'match',
        'title': 'Match!',
        'message': 'You have a match',
        'createdAt': Timestamp.now(),
        'isRead': false,
      };

      final model = NotificationModel.fromMap(map, 'id1');
      expect(model.content, 'You have a match');
    });

    test('should prefer content over message', () {
      final map = {
        'userId': 'user1',
        'type': 'match',
        'title': 'Match!',
        'content': 'New content',
        'message': 'Old message',
        'createdAt': Timestamp.now(),
        'isRead': false,
      };

      final model = NotificationModel.fromMap(map, 'id1');
      expect(model.content, 'New content');
    });

    test('should handle deeplink', () {
      final map = {
        'userId': 'user1',
        'type': 'match',
        'title': 'Match!',
        'content': 'You have a match',
        'deeplink': '/chat/123',
        'createdAt': Timestamp.now(),
        'isRead': false,
      };

      final model = NotificationModel.fromMap(map, 'id1');
      expect(model.deeplink, '/chat/123');
    });

    test('toMap should include content and deeplink', () {
      final model = NotificationModel(
        id: 'id1',
        userId: 'user1',
        type: 'match',
        title: 'Match!',
        content: 'You have a match',
        deeplink: '/chat/123',
        createdAt: DateTime.now(),
      );

      final map = model.toMap();
      expect(map['content'], 'You have a match');
      expect(map['deeplink'], '/chat/123');
      expect(map.containsKey('message'), false); // assuming we don't save message anymore
    });
  });
}

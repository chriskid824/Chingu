import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationModel', () {
    test('should correctly serialize and deserialize trackingData', () {
      final now = DateTime.now();
      final model = NotificationModel(
        id: '123',
        userId: 'user1',
        type: 'match',
        title: 'Title',
        message: 'Message',
        createdAt: now,
        trackingData: {'groupId': 'variant', 'originalType': 'match'},
      );

      final map = model.toMap();
      expect(map['trackingData'], {'groupId': 'variant', 'originalType': 'match'});

      final newModel = NotificationModel.fromMap(map, '123');
      expect(newModel.trackingData, {'groupId': 'variant', 'originalType': 'match'});
    });

    test('should handle null trackingData', () {
      final now = DateTime.now();
      final model = NotificationModel(
        id: '123',
        userId: 'user1',
        type: 'match',
        title: 'Title',
        message: 'Message',
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['trackingData'], null);

      final newModel = NotificationModel.fromMap(map, '123');
      expect(newModel.trackingData, null);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/login_history_model.dart';

void main() {
  group('LoginHistoryModel Tests', () {
    test('toMap should return correct map', () {
      final now = DateTime.now();
      final history = LoginHistoryModel(
        id: 'test_id',
        userId: 'user_123',
        loginTime: now,
        location: 'Taipei, Taiwan',
        deviceInfo: 'Android',
        ipAddress: '127.0.0.1',
      );

      final map = history.toMap();

      expect(map['userId'], 'user_123');
      expect(map['location'], 'Taipei, Taiwan');
      expect(map['deviceInfo'], 'Android');
      expect(map['ipAddress'], '127.0.0.1');
      expect(map['loginTime'], isA<Timestamp>());
    });

    test('fromMap should return correct object', () {
      final now = DateTime.now();
      final map = {
        'userId': 'user_123',
        'loginTime': Timestamp.fromDate(now),
        'location': 'Taipei, Taiwan',
        'deviceInfo': 'Android',
        'ipAddress': '127.0.0.1',
      };

      final history = LoginHistoryModel.fromMap(map, 'test_id');

      expect(history.id, 'test_id');
      expect(history.userId, 'user_123');
      // Using closeTo for DateTime comparison to avoid microsecond precision issues
      expect(
          history.loginTime.millisecondsSinceEpoch,
          closeTo(now.millisecondsSinceEpoch, 1000));
      expect(history.location, 'Taipei, Taiwan');
      expect(history.deviceInfo, 'Android');
      expect(history.ipAddress, '127.0.0.1');
    });
  });
}

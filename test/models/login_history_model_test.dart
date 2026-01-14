import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/login_history_model.dart';

void main() {
  group('LoginHistoryModel Tests', () {
    test('should create LoginHistoryModel instance correctly', () {
      final now = DateTime.now();
      final history = LoginHistoryModel(
        id: '123',
        timestamp: now,
        deviceName: 'iPhone 13',
        location: 'Taipei',
        ipAddress: '192.168.1.1',
        osVersion: 'iOS 15',
      );

      expect(history.id, '123');
      expect(history.timestamp, now);
      expect(history.deviceName, 'iPhone 13');
      expect(history.location, 'Taipei');
      expect(history.ipAddress, '192.168.1.1');
      expect(history.osVersion, 'iOS 15');
    });

    test('should serialize to map correctly', () {
      final now = DateTime.now();
      final history = LoginHistoryModel(
        id: '123',
        timestamp: now,
        deviceName: 'iPhone 13',
        location: 'Taipei',
        ipAddress: '192.168.1.1',
        osVersion: 'iOS 15',
      );

      final map = history.toMap();

      expect(map['timestamp'], isA<Timestamp>());
      expect((map['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch,
             now.millisecondsSinceEpoch);
      expect(map['deviceName'], 'iPhone 13');
      expect(map['location'], 'Taipei');
      expect(map['ipAddress'], '192.168.1.1');
      expect(map['osVersion'], 'iOS 15');
    });
  });
}

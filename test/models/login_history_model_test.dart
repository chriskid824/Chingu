import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/login_history_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('LoginHistoryModel', () {
    test('should correctly parse from map', () {
      final now = DateTime.now();
      // Firestore Timestamp has microsecond precision issues in tests sometimes,
      // but usually toDate() matches if we don't look at microseconds.
      final timestamp = Timestamp.fromDate(now);

      final map = {
        'userId': 'user123',
        'timestamp': timestamp,
        'location': 'Taipei',
        'deviceInfo': 'iPhone',
        'ipAddress': '192.168.1.1',
      };

      final model = LoginHistoryModel.fromMap(map, 'doc123');

      expect(model.id, 'doc123');
      expect(model.userId, 'user123');
      // Compare millisecond precision
      expect(model.timestamp.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(model.location, 'Taipei');
      expect(model.deviceInfo, 'iPhone');
      expect(model.ipAddress, '192.168.1.1');
    });

    test('should correctly convert to map', () {
      final now = DateTime.now();
      final model = LoginHistoryModel(
        id: 'doc123',
        userId: 'user123',
        timestamp: now,
        location: 'Taipei',
        deviceInfo: 'iPhone',
        ipAddress: '192.168.1.1',
      );

      final map = model.toMap();

      expect(map['userId'], 'user123');
      expect((map['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(map['location'], 'Taipei');
      expect(map['deviceInfo'], 'iPhone');
      expect(map['ipAddress'], '192.168.1.1');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/login_history_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('LoginHistoryModel', () {
    test('toMap returns correct map', () {
      final timestamp = DateTime(2023, 10, 26, 12, 0, 0);
      final history = LoginHistoryModel(
        id: 'test_id',
        uid: 'user_123',
        timestamp: timestamp,
        deviceName: 'Pixel 5',
        deviceOs: 'Android 14',
        ipAddress: '192.168.1.1',
        location: 'Taipei, Taiwan',
      );

      final map = history.toMap();

      expect(map['uid'], 'user_123');
      expect(map['timestamp'], isA<Timestamp>());
      expect((map['timestamp'] as Timestamp).toDate(), timestamp);
      expect(map['deviceName'], 'Pixel 5');
      expect(map['deviceOs'], 'Android 14');
      expect(map['ipAddress'], '192.168.1.1');
      expect(map['location'], 'Taipei, Taiwan');
    });

    test('fromMap creates correct model', () {
      final timestamp = DateTime(2023, 10, 26, 12, 0, 0);
      final map = {
        'uid': 'user_123',
        'timestamp': Timestamp.fromDate(timestamp),
        'deviceName': 'Pixel 5',
        'deviceOs': 'Android 14',
        'ipAddress': '192.168.1.1',
        'location': 'Taipei, Taiwan',
      };

      final history = LoginHistoryModel.fromMap(map, 'test_id');

      expect(history.id, 'test_id');
      expect(history.uid, 'user_123');
      expect(history.timestamp, timestamp);
      expect(history.deviceName, 'Pixel 5');
      expect(history.deviceOs, 'Android 14');
      expect(history.ipAddress, '192.168.1.1');
      expect(history.location, 'Taipei, Taiwan');
    });

    test('fromMap handles missing fields with defaults', () {
      final timestamp = DateTime.now();
      final map = {
        'timestamp': Timestamp.fromDate(timestamp),
      };

      final history = LoginHistoryModel.fromMap(map, 'test_id');

      expect(history.id, 'test_id');
      expect(history.uid, '');
      expect(history.timestamp.millisecondsSinceEpoch, timestamp.millisecondsSinceEpoch);
      expect(history.deviceName, '');
      expect(history.deviceOs, '');
      expect(history.ipAddress, '');
      expect(history.location, '');
    });
  });
}

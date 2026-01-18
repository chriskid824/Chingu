import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/login_history_model.dart';

void main() {
  group('LoginHistoryModel', () {
    final timestamp = DateTime.now();
    final timestampData = Timestamp.fromDate(timestamp);

    test('fromMap creates valid instance', () {
      final data = {
        'timestamp': timestampData,
        'ipAddress': '192.168.1.1',
        'location': 'Taipei, Taiwan',
        'device': 'Android 12',
      };

      final model = LoginHistoryModel.fromMap(data, 'test_id');

      expect(model.id, 'test_id');
      expect(model.timestamp, timestamp);
      expect(model.ipAddress, '192.168.1.1');
      expect(model.location, 'Taipei, Taiwan');
      expect(model.device, 'Android 12');
    });

    test('fromMap handles missing fields with defaults', () {
      final data = {
        'timestamp': timestampData,
      };

      final model = LoginHistoryModel.fromMap(data, 'test_id');

      expect(model.ipAddress, 'Unknown');
      expect(model.location, 'Unknown');
      expect(model.device, 'Unknown');
    });

    test('toMap creates valid map', () {
      final model = LoginHistoryModel(
        id: 'test_id',
        timestamp: timestamp,
        ipAddress: '127.0.0.1',
        location: 'Localhost',
        device: 'Test Device',
      );

      final map = model.toMap();

      expect(map['timestamp'], isA<Timestamp>());
      expect((map['timestamp'] as Timestamp).toDate(), timestamp);
      expect(map['ipAddress'], '127.0.0.1');
      expect(map['location'], 'Localhost');
      expect(map['device'], 'Test Device');
    });
  });
}

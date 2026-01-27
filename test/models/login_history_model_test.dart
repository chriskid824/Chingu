import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/login_history_model.dart';

void main() {
  group('LoginHistoryModel', () {
    test('toMap returns correct map', () {
      final timestamp = DateTime.now();
      final model = LoginHistoryModel(
        id: '123',
        userId: 'user1',
        timestamp: timestamp,
        device: 'Pixel 5',
        location: 'Taipei, Taiwan',
        ipAddress: '192.168.1.1',
      );

      final map = model.toMap();

      expect(map['userId'], 'user1');
      expect(map['device'], 'Pixel 5');
      expect(map['location'], 'Taipei, Taiwan');
      expect(map['ipAddress'], '192.168.1.1');
      // Precision might be lost in Timestamp conversion, so we compare milliseconds
      expect((map['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch,
             timestamp.millisecondsSinceEpoch);
    });

    test('fromMap creates correct model', () {
      final timestamp = DateTime.now();
      final map = {
        'userId': 'user1',
        'timestamp': Timestamp.fromDate(timestamp),
        'device': 'Pixel 5',
        'location': 'Taipei, Taiwan',
        'ipAddress': '192.168.1.1',
      };

      final model = LoginHistoryModel.fromMap(map, '123');

      expect(model.id, '123');
      expect(model.userId, 'user1');
      expect(model.device, 'Pixel 5');
      expect(model.location, 'Taipei, Taiwan');
      expect(model.ipAddress, '192.168.1.1');
      expect(model.timestamp.millisecondsSinceEpoch, timestamp.millisecondsSinceEpoch);
    });

    test('fromMap handles missing fields with defaults', () {
      final map = <String, dynamic>{};
      final model = LoginHistoryModel.fromMap(map, '123');

      expect(model.id, '123');
      expect(model.userId, '');
      expect(model.device, 'Unknown Device');
      expect(model.location, 'Unknown Location');
      expect(model.ipAddress, null);
      expect(model.timestamp, isA<DateTime>());
    });
  });
}

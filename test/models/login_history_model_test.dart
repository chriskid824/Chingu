import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/login_history_model.dart';

void main() {
  group('LoginHistoryModel', () {
    test('toMap and fromMap work correctly', () {
      final now = DateTime.now();
      final model = LoginHistoryModel(
        id: '123',
        timestamp: now,
        device: 'Pixel 5',
        location: 'Taipei',
        ipAddress: '127.0.0.1',
      );

      final map = model.toMap();
      expect(map['device'], 'Pixel 5');
      expect(map['location'], 'Taipei');
      expect(map['ipAddress'], '127.0.0.1');
      expect(map['timestamp'], now.millisecondsSinceEpoch);

      final newModel = LoginHistoryModel.fromMap(map, '123');
      expect(newModel.id, '123');
      expect(newModel.device, 'Pixel 5');
      expect(newModel.location, 'Taipei');
      expect(newModel.ipAddress, '127.0.0.1');
      // Precision might be lost due to milliseconds
      expect(newModel.timestamp.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });
  });
}

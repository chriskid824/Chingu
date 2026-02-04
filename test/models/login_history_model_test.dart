import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/login_history_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('LoginHistoryModel', () {
    test('toMap returns correct map', () {
      final history = LoginHistoryModel(
        id: 'test_id',
        timestamp: DateTime(2023, 1, 1),
        location: 'Taipei',
        device: 'Pixel 5',
        ipAddress: '127.0.0.1',
      );

      final map = history.toMap();

      expect(map['location'], 'Taipei');
      expect(map['device'], 'Pixel 5');
      expect(map['ipAddress'], '127.0.0.1');
      expect(map['timestamp'], isA<Timestamp>());
    });

    test('fromFirestore creates correct model', () async {
      final instance = FakeFirebaseFirestore();
      await instance.collection('users').doc('uid').collection('login_history').doc('doc_id').set({
        'timestamp': Timestamp.fromDate(DateTime(2023, 1, 1)),
        'location': 'Taipei',
        'device': 'Pixel 5',
        'ipAddress': '127.0.0.1',
      });

      final doc = await instance.collection('users').doc('uid').collection('login_history').doc('doc_id').get();
      final history = LoginHistoryModel.fromFirestore(doc);

      expect(history.id, 'doc_id');
      expect(history.location, 'Taipei');
      expect(history.device, 'Pixel 5');
      expect(history.timestamp, DateTime(2023, 1, 1));
    });
  });
}

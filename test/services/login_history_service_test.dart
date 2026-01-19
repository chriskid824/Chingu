import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/login_history_service.dart';
import 'package:chingu/models/login_history_model.dart';

void main() {
  group('LoginHistoryService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late LoginHistoryService service;
    final userId = 'test_user_id';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = LoginHistoryService(firestore: fakeFirestore);
    });

    test('recordLogin adds a document to Firestore', () async {
      await service.recordLogin(userId, location: 'Taipei');

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .get();

      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['userId'], userId);
      expect(data['location'], 'Taipei');
      // device info might vary, just checking it exists
      expect(data.containsKey('deviceInfo'), true);
    });

    test('recordLogin fetches location from user profile if not provided', () async {
      // Setup user profile
      await fakeFirestore.collection('users').doc(userId).set({
        'city': 'New York',
        'country': 'USA',
      });

      await service.recordLogin(userId); // No location provided

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .get();

      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['location'], 'New York, USA');
    });

    test('getLoginHistory retrieves documents ordered by timestamp', () async {
      final now = DateTime.now();

      // Old record
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .add(LoginHistoryModel(
            id: '1',
            userId: userId,
            timestamp: now.subtract(const Duration(hours: 1)),
            location: 'Old',
            deviceInfo: 'Device 1',
          ).toMap());

      // New record
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .add(LoginHistoryModel(
            id: '2',
            userId: userId,
            timestamp: now,
            location: 'New',
            deviceInfo: 'Device 2',
          ).toMap());

      final history = await service.getLoginHistory(userId);

      expect(history.length, 2);
      expect(history.first.location, 'New'); // Newest first
      expect(history.last.location, 'Old');
    });
  });
}

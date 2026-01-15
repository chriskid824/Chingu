import 'package:chingu/services/firestore_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FirestoreService firestoreService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
  });

  group('updateFcmToken', () {
    test('should update token for existing user', () async {
      const uid = 'user1';
      const token = 'token123';

      await fakeFirestore.collection('users').doc(uid).set({
        'name': 'Test User',
      });

      await firestoreService.updateFcmToken(uid, token);

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()?['fcmToken'], token);
      expect(doc.data()?['lastTokenUpdate'], isNotNull);
    });

    test('should create document with token for non-existing user (merge)', () async {
      const uid = 'user2';
      const token = 'token456';

      await firestoreService.updateFcmToken(uid, token);

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.exists, true);
      expect(doc.data()?['fcmToken'], token);
    });
  });
}

import 'package:chingu/services/firestore_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreService firestoreService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      firestoreService = FirestoreService(firestore: fakeFirestore);
    });

    test('submitFeedback adds document to feedback collection', () async {
      await firestoreService.submitFeedback(
        userId: 'user123',
        feedbackType: 'suggestion',
        content: 'Great app!',
        contactEmail: 'test@example.com',
        platform: 'Android',
        deviceInfo: 'Pixel 5',
        appVersion: '1.0.0',
      );

      final snapshot = await fakeFirestore.collection('feedback').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['userId'], 'user123');
      expect(data['feedbackType'], 'suggestion');
      expect(data['content'], 'Great app!');
      expect(data['status'], 'new');
      expect(data['createdAt'], isNotNull);
    });
  });
}

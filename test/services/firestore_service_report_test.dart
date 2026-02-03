import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/report_model.dart';

void main() {
  group('FirestoreService Report Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreService firestoreService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      firestoreService = FirestoreService(firestore: fakeFirestore);
    });

    test('submitReport adds report to firestore', () async {
      final report = ReportModel(
        reporterId: 'reporter_1',
        reportedUserId: 'reported_1',
        reason: 'Spam',
        description: 'Test description',
        createdAt: DateTime.now(),
      );

      await firestoreService.submitReport(report);

      final snapshot = await fakeFirestore.collection('reports').get();
      expect(snapshot.docs.length, 1);

      final data = snapshot.docs.first.data();
      expect(data['reporterId'], 'reporter_1');
      expect(data['reportedUserId'], 'reported_1');
      expect(data['reason'], 'Spam');
      expect(data['status'], 'pending');
    });
  });
}

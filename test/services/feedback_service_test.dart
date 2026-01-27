import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/models/feedback_model.dart';
import 'package:chingu/services/feedback_service.dart';

void main() {
  group('FeedbackService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FeedbackService feedbackService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      feedbackService = FeedbackService(firestore: fakeFirestore);
    });

    test('submitFeedback adds document to firestore', () async {
      final feedback = FeedbackModel(
        userId: 'user_123',
        type: 'suggestion',
        content: 'Great app!',
        createdAt: DateTime.now(),
      );

      await feedbackService.submitFeedback(feedback);

      final snapshot = await fakeFirestore.collection('feedback').get();
      expect(snapshot.docs.length, 1);

      final doc = snapshot.docs.first;
      expect(doc['userId'], 'user_123');
      expect(doc['type'], 'suggestion');
      expect(doc['content'], 'Great app!');
      expect(doc['status'], 'pending');
    });
  });
}

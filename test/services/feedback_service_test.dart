import 'package:chingu/models/feedback_model.dart';
import 'package:chingu/services/feedback_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FeedbackService feedbackService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    feedbackService = FeedbackService(firestore: fakeFirestore);
  });

  test('submitFeedback should add feedback to firestore', () async {
    final feedback = FeedbackModel(
      userId: 'user1',
      type: 'suggestion',
      content: 'Great app!',
      createdAt: DateTime.now(),
    );

    await feedbackService.submitFeedback(feedback);

    final snapshot = await fakeFirestore.collection('feedback').get();
    expect(snapshot.docs.length, 1);
    expect(snapshot.docs.first['userId'], 'user1');
    expect(snapshot.docs.first['content'], 'Great app!');
  });
}

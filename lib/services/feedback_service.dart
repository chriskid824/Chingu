import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _feedbackCollection => _firestore.collection('feedback');

  Future<void> submitFeedback(FeedbackModel feedback) async {
    try {
      await _feedbackCollection.doc(feedback.id).set(feedback.toMap());
    } catch (e) {
      throw Exception('提交回饋失敗: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore;

  FeedbackService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> submitFeedback(FeedbackModel feedback) async {
    try {
      await _firestore.collection('feedback').add(feedback.toMap());
    } catch (e) {
      throw Exception('提交回饋失敗: $e');
    }
  }
}

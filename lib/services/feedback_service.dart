import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore;

  FeedbackService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _feedbackCollection => _firestore.collection('feedback');

  /// 提交用戶反饋
  Future<void> submitFeedback(FeedbackModel feedback) async {
    try {
      await _feedbackCollection.add(feedback.toMap());
    } catch (e) {
      throw Exception('提交反饋失敗: $e');
    }
  }
}

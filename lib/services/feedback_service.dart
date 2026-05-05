import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'feedback';

  Future<void> submitFeedback(FeedbackModel feedback) async {
    try {
      await _firestore.collection(_collectionName).add(feedback.toMap());
    } catch (e) {
      throw Exception('提交回饋失敗: $e');
    }
  }
}

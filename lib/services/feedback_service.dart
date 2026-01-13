import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _feedbackCollection => _firestore.collection('feedback');

  Future<void> submitFeedback(FeedbackModel feedback) async {
    try {
      await _feedbackCollection.add(feedback.toMap());
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }
}

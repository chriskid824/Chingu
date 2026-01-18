import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _feedbackCollection => _firestore.collection('feedback');

  /// 提交反饋
  Future<void> submitFeedback(FeedbackModel feedback) async {
    try {
      // Create a new document reference with an auto-generated ID if id is empty,
      // or use the provided ID. But usually we let Firestore generate ID.
      // The FeedbackModel passed in might have a dummy ID or we ignore it.

      // Using add() automatically generates an ID.
      // We will exclude 'id' from the map since it's the doc ID.
      await _feedbackCollection.add(feedback.toMap());
    } catch (e) {
      throw Exception('提交反饋失敗: $e');
    }
  }

  /// 獲取用戶的反饋歷史 (可選)
  Future<List<FeedbackModel>> getUserFeedback(String userId) async {
    try {
      final querySnapshot = await _feedbackCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return FeedbackModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('獲取反饋歷史失敗: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'moments';

  /// Create a new moment
  Future<void> createMoment(MomentModel moment) async {
    try {
      await _firestore.collection(_collection).add(moment.toMap());
    } catch (e) {
      throw Exception('Failed to create moment: $e');
    }
  }

  /// Get moments stream, optionally filtered by userId
  Stream<List<MomentModel>> getMomentsStream({String? userId, int limit = 20}) {
    Query query = _firestore.collection(_collection).orderBy('createdAt', descending: true);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => MomentModel.fromFirestore(doc)).toList();
    });
  }

  /// Delete a moment
  Future<void> deleteMoment(String momentId) async {
    try {
      await _firestore.collection(_collection).doc(momentId).delete();
    } catch (e) {
      throw Exception('Failed to delete moment: $e');
    }
  }
}

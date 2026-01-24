import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/models/comment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _momentsRef => _firestore.collection('moments');

  /// Like a moment
  Future<void> likeMoment(String momentId, String userId) async {
    final momentRef = _momentsRef.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      if (!likeDoc.exists) {
        transaction.set(likeRef, {
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(momentRef, {
          'likeCount': FieldValue.increment(1),
        });
      }
    });
  }

  /// Unlike a moment
  Future<void> unlikeMoment(String momentId, String userId) async {
    final momentRef = _momentsRef.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      if (likeDoc.exists) {
        transaction.delete(likeRef);
        transaction.update(momentRef, {
          'likeCount': FieldValue.increment(-1),
        });
      }
    });
  }

  /// Add a comment
  Future<void> addComment(String momentId, CommentModel comment) async {
    final momentRef = _momentsRef.doc(momentId);
    final commentsRef = momentRef.collection('comments');

    await _firestore.runTransaction((transaction) async {
      // Usually we let Firestore generate ID.
      // But CommentModel has an ID.
      // If comment.id is empty, we generate one.

      final docRef = comment.id.isEmpty ? commentsRef.doc() : commentsRef.doc(comment.id);

      transaction.set(docRef, comment.toMap());
      transaction.update(momentRef, {
        'commentCount': FieldValue.increment(1),
      });
    });
  }

  /// Get comments stream
  Stream<List<CommentModel>> getCommentsStream(String momentId) {
    return _momentsRef
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommentModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Get moment stream (updates only likeCount/commentCount/content)
  /// Note: This does NOT update isLiked status for a specific user dynamically
  /// without extra logic.
  Stream<MomentModel> getMomentStream(String momentId) {
    return _momentsRef.doc(momentId).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception('Moment not found');
      }
      return MomentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Check if a moment is liked by user
  Future<bool> isLiked(String momentId, String userId) async {
    final doc = await _momentsRef
        .doc(momentId)
        .collection('likes')
        .doc(userId)
        .get();
    return doc.exists;
  }
}

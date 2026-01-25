import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/models.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _momentsCollection => _firestore.collection('moments');

  /// Toggle like status for a moment
  Future<void> toggleLike(String momentId, String userId) async {
    final momentRef = _momentsCollection.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final likeDoc = await transaction.get(likeRef);

        if (likeDoc.exists) {
          // Unlike
          transaction.delete(likeRef);
          transaction.update(momentRef, {
            'likeCount': FieldValue.increment(-1),
          });
        } else {
          // Like
          transaction.set(likeRef, {
            'userId': userId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(momentRef, {
            'likeCount': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Get real-time stream of comments for a moment
  Stream<List<CommentModel>> getCommentsStream(String momentId) {
    return _momentsCollection
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommentModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Add a comment to a moment
  Future<void> addComment(String momentId, CommentModel comment) async {
    try {
      final momentRef = _momentsCollection.doc(momentId);
      final commentsRef = momentRef.collection('comments');

      await _firestore.runTransaction((transaction) async {
        // Create a new document reference
        final newCommentRef = commentsRef.doc();

        // Prepare data
        final data = comment.toMap();
        data.remove('id'); // ID is the document ID
        // Use server timestamp for consistency
        data['createdAt'] = FieldValue.serverTimestamp();

        transaction.set(newCommentRef, data);
        transaction.update(momentRef, {
          'commentCount': FieldValue.increment(1),
        });
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Delete a comment from a moment
  Future<void> deleteComment(String momentId, String commentId) async {
    try {
      final momentRef = _momentsCollection.doc(momentId);
      final commentRef = momentRef.collection('comments').doc(commentId);

      await _firestore.runTransaction((transaction) async {
        transaction.delete(commentRef);
        transaction.update(momentRef, {
          'commentCount': FieldValue.increment(-1),
        });
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/models.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _momentsRef => _firestore.collection('moments');

  Future<void> toggleLike(String momentId, String userId) async {
    final momentRef = _momentsRef.doc(momentId);
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

  Stream<List<CommentModel>> getComments(String momentId) {
    return _momentsRef
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt', descending: false) // Comments usually ascending
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CommentModel.fromMap(data);
      }).toList();
    });
  }

  Future<void> addComment(String momentId, CommentModel comment) async {
    final momentRef = _momentsRef.doc(momentId);
    final commentsRef = momentRef.collection('comments');

    try {
      await _firestore.runTransaction((transaction) async {
        final newCommentRef = commentsRef.doc(); // Auto-id
        var commentData = comment.toMap();
        commentData['id'] = newCommentRef.id; // Ensure ID is set

        transaction.set(newCommentRef, commentData);
        transaction.update(momentRef, {
          'commentCount': FieldValue.increment(1),
        });
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }
}

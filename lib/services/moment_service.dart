import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/comment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<CommentModel>> getCommentsStream(String momentId) {
    return _firestore
        .collection('moments')
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

  Future<void> addComment(String momentId, CommentModel comment) async {
    final batch = _firestore.batch();
    final commentRef = _firestore
        .collection('moments')
        .doc(momentId)
        .collection('comments')
        .doc();

    batch.set(commentRef, comment.toMap());

    final momentRef = _firestore.collection('moments').doc(momentId);
    batch.update(momentRef, {
      'commentCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> toggleLike(String momentId, String userId, bool isLiked) async {
    final momentRef = _firestore.collection('moments').doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    // If isLiked is true, it means the user JUST toggled it to be liked (so we add a like).
    // Wait, the parameter meaning depends on usage.
    // Usually toggleLike(..., isLiked) means "set it to isLiked".
    // Let's assume isLiked is the NEW state.

    if (isLiked) {
      // User wants to like
       await _firestore.runTransaction((transaction) async {
         final likeDoc = await transaction.get(likeRef);
         if (!likeDoc.exists) {
           transaction.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
           transaction.update(momentRef, {'likeCount': FieldValue.increment(1)});
         }
       });
    } else {
      // User wants to unlike
      await _firestore.runTransaction((transaction) async {
         final likeDoc = await transaction.get(likeRef);
         if (likeDoc.exists) {
           transaction.delete(likeRef);
           transaction.update(momentRef, {'likeCount': FieldValue.increment(-1)});
         }
       });
    }
  }
}

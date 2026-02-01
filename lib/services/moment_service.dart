import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/comment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore;

  MomentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> likeMoment(String momentId, String userId) async {
    final momentRef = _firestore.collection('moments').doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      if (likeDoc.exists) {
        return; // Already liked
      }

      transaction.update(momentRef, {
        'likeCount': FieldValue.increment(1),
      });
      transaction.set(likeRef, {
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> unlikeMoment(String momentId, String userId) async {
    final momentRef = _firestore.collection('moments').doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      if (!likeDoc.exists) {
        return; // Not liked
      }

      transaction.update(momentRef, {
        'likeCount': FieldValue.increment(-1),
      });
      transaction.delete(likeRef);
    });
  }

  Future<void> addComment(String momentId, CommentModel comment) async {
    final momentRef = _firestore.collection('moments').doc(momentId);
    DocumentReference commentRef;

    if (comment.id.isEmpty) {
      commentRef = momentRef.collection('comments').doc();
    } else {
      commentRef = momentRef.collection('comments').doc(comment.id);
    }

    final commentData = comment.toMap();
    commentData['id'] = commentRef.id; // Ensure ID matches doc ID

    await _firestore.runTransaction((transaction) async {
      transaction.update(momentRef, {
        'commentCount': FieldValue.increment(1),
      });
      transaction.set(commentRef, commentData);
    });
  }

  Stream<List<CommentModel>> getCommentsStream(String momentId) {
    return _firestore
        .collection('moments')
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}

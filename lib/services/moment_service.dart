import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/comment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore;

  MomentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> likeMoment(String momentId, String userId) async {
    final momentRef = _firestore.collection('moments').doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    return _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      if (!likeDoc.exists) {
        transaction.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
        transaction.update(momentRef, {'likeCount': FieldValue.increment(1)});
      }
    });
  }

  Future<void> unlikeMoment(String momentId, String userId) async {
    final momentRef = _firestore.collection('moments').doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    return _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      if (likeDoc.exists) {
        transaction.delete(likeRef);
        transaction.update(momentRef, {'likeCount': FieldValue.increment(-1)});
      }
    });
  }

  Future<void> addComment(String momentId, String userId, String userName, String? userAvatar, String content) async {
    final momentRef = _firestore.collection('moments').doc(momentId);
    final commentsRef = momentRef.collection('comments');

    await _firestore.runTransaction((transaction) async {
      final newCommentRef = commentsRef.doc();
      transaction.set(newCommentRef, {
        'momentId': momentId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(momentRef, {'commentCount': FieldValue.increment(1)});
    });
  }

  Stream<List<CommentModel>> getCommentsStream(String momentId) {
    return _firestore
        .collection('moments')
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}

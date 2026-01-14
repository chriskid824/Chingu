import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/comment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _moments => _firestore.collection('moments');

  /// Toggles like status for a moment
  ///
  /// [momentId] ID of the moment
  /// [userId] ID of the user performing the action
  /// [isLiked] Current like status (true means currently liked, so we want to unlike)
  Future<void> toggleLike(String momentId, String userId, bool isLiked) async {
    final momentRef = _moments.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final momentDoc = await transaction.get(momentRef);
      if (!momentDoc.exists) {
        throw Exception("Moment does not exist");
      }

      if (isLiked) {
        // Was liked, so unlike it
        transaction.delete(likeRef);
        transaction.update(momentRef, {'likeCount': FieldValue.increment(-1)});
      } else {
        // Was not liked, so like it
        transaction.set(likeRef, {
          'userId': userId,
          'likedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(momentRef, {'likeCount': FieldValue.increment(1)});
      }
    });
  }

  /// Get comments stream for a moment
  Stream<List<CommentModel>> getCommentsStream(String momentId) {
    return _moments
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommentModel.fromMap(doc.data(), id: doc.id);
      }).toList();
    });
  }

  /// Add a comment to a moment
  Future<void> addComment(
    String momentId,
    String userId,
    String userName,
    String? userAvatar,
    String content,
  ) async {
    final momentRef = _moments.doc(momentId);
    final commentsRef = momentRef.collection('comments');

    await _firestore.runTransaction((transaction) async {
      final newCommentRef = commentsRef.doc();
      final commentData = {
        'momentId': momentId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
      };

      transaction.set(newCommentRef, commentData);
      transaction.update(momentRef, {'commentCount': FieldValue.increment(1)});
    });
  }
}

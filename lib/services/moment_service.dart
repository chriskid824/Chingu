import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/comment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore;

  MomentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _momentsCollection => _firestore.collection('moments');

  // Toggle Like
  Future<void> toggleLike(String momentId, String userId) async {
    final momentRef = _momentsCollection.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    return _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);

      if (likeDoc.exists) {
        // Unlike
        transaction.delete(likeRef);
        transaction.update(momentRef, {
          'likeCount': FieldValue.increment(-1),
          // We can't easily update isLiked in the moment doc for a specific user without a subcollection check
          // The UI should handle isLiked state based on whether the user is in the likes subcollection or
          // if we maintain an array of likedUserIds (but that has limits).
          // For now, we just update the count.
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
  }

  // Check if liked
  Future<bool> isLiked(String momentId, String userId) async {
    final doc = await _momentsCollection.doc(momentId).collection('likes').doc(userId).get();
    return doc.exists;
  }

  // Get Comments Stream
  Stream<List<CommentModel>> getCommentsStream(String momentId) {
    return _momentsCollection
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CommentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  // Add Comment
  Future<void> addComment(String momentId, String userId, String content, String userName, String? userAvatar) async {
    final momentRef = _momentsCollection.doc(momentId);
    final commentsCollection = momentRef.collection('comments');

    return _firestore.runTransaction((transaction) async {
      // Add comment doc
      final newCommentRef = commentsCollection.doc();
      transaction.set(newCommentRef, {
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment comment count
      transaction.update(momentRef, {
        'commentCount': FieldValue.increment(1),
      });
    });
  }

  // Delete Comment
  Future<void> deleteComment(String momentId, String commentId) async {
     final momentRef = _momentsCollection.doc(momentId);
     final commentRef = momentRef.collection('comments').doc(commentId);

     return _firestore.runTransaction((transaction) async {
       transaction.delete(commentRef);
       transaction.update(momentRef, {
         'commentCount': FieldValue.increment(-1),
       });
     });
  }
}

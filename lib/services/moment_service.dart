import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/models/comment_model.dart';
import 'package:chingu/services/firestore_service.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Collection References
  CollectionReference get _momentsCollection => _firestore.collection('moments');

  /// Toggle like status for a moment
  Future<void> toggleLike(String momentId, bool isLiked) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final momentRef = _momentsCollection.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(user.uid);

    try {
      await _firestore.runTransaction((transaction) async {
        final likeDoc = await transaction.get(likeRef);
        final momentDoc = await transaction.get(momentRef);

        if (!momentDoc.exists) {
          throw Exception('Moment does not exist');
        }

        if (likeDoc.exists) {
          // Unlike
          transaction.delete(likeRef);
          transaction.update(momentRef, {
            'likeCount': FieldValue.increment(-1),
          });
        } else {
          // Like
          transaction.set(likeRef, {
            'userId': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(momentRef, {
            'likeCount': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      print('Error toggling like: $e');
      throw e;
    }
  }

  /// Get comments for a moment
  Stream<List<CommentModel>> getComments(String momentId) {
    return _momentsCollection
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

  /// Add a comment to a moment
  Future<void> addComment(String momentId, String content) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    if (content.trim().isEmpty) return;

    try {
      // Get latest user info to ensure avatar/name is up to date
      final userModel = await _firestoreService.getUser(user.uid);
      final userName = userModel?.name ?? user.displayName ?? 'Unknown';
      final userAvatar = userModel?.avatarUrl ?? user.photoURL;

      final commentData = {
        'momentId': momentId,
        'userId': user.uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'content': content.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.runTransaction((transaction) async {
        final momentRef = _momentsCollection.doc(momentId);
        final commentRef = momentRef.collection('comments').doc();

        transaction.set(commentRef, commentData);
        transaction.update(momentRef, {
          'commentCount': FieldValue.increment(1),
        });
      });
    } catch (e) {
      print('Error adding comment: $e');
      throw e;
    }
  }
}

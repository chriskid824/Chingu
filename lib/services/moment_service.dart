import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/models/comment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of moments for a specific user
  Stream<List<MomentModel>> getMoments(String userId) {
    final currentUserId = _auth.currentUser?.uid;

    return _firestore
        .collection('moments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final moments = <MomentModel>[];
      for (var doc in snapshot.docs) {
        bool isLiked = false;
        if (currentUserId != null) {
          // Check if current user liked this moment
          final likeDoc = await doc.reference
              .collection('likes')
              .doc(currentUserId)
              .get();
          isLiked = likeDoc.exists;
        }
        moments.add(MomentModel.fromMap(doc.data(), doc.id, isLiked: isLiked));
      }
      return moments;
    });
  }

  // Toggle Like: shouldLike = true means we want to add a like
  Future<void> toggleLike(String momentId, bool shouldLike) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final momentRef = _firestore.collection('moments').doc(momentId);
    final likeRef = momentRef.collection('likes').doc(user.uid);

    return _firestore.runTransaction((transaction) async {
      final momentDoc = await transaction.get(momentRef);
      if (!momentDoc.exists) return;

      final likeDoc = await transaction.get(likeRef);

      if (shouldLike) {
        if (likeDoc.exists) return; // Already liked

        transaction.set(likeRef, {
          'likedAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
        });
        transaction.update(momentRef, {
          'likeCount': FieldValue.increment(1),
        });
      } else {
        if (!likeDoc.exists) return; // Already unliked

        transaction.delete(likeRef);
        transaction.update(momentRef, {
          'likeCount': FieldValue.increment(-1),
        });
      }
    });
  }

  // Get Comments
  Stream<List<CommentModel>> getComments(String momentId) {
    return _firestore
        .collection('moments')
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt', descending: true) // Newest first usually? Or Oldest first? Chats are newest bottom. Comments usually newest top or bottom. Let's do newest top (descending).
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommentModel.fromMap(doc.data(), doc.id, momentId: momentId))
          .toList();
    });
  }

  // Add Comment
  Future<void> addComment(String momentId, String content) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    if (content.trim().isEmpty) return;

    // Fetch user details for the comment
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final userName = userData?['name'] ?? 'User';
    final userAvatar = userData?['avatarUrl'];

    final commentRef = _firestore
        .collection('moments')
        .doc(momentId)
        .collection('comments')
        .doc();

    final momentRef = _firestore.collection('moments').doc(momentId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(commentRef, {
        'momentId': momentId,
        'userId': user.uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(momentRef, {
        'commentCount': FieldValue.increment(1),
      });
    });
  }
}

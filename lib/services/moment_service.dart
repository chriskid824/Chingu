import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/models/comment_model.dart';
import 'package:chingu/models/moment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _momentsCollection => _firestore.collection('moments');

  /// Toggle like status for a moment
  Future<void> toggleLike(String momentId, bool isLiked) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

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

  /// Get comments for a moment
  Stream<List<CommentModel>> getComments(String momentId) {
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
  Future<void> addComment(String momentId, String content) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    if (content.trim().isEmpty) return;

    try {
      // Get user details for the comment
      // Ideally we fetch this from Firestore to get the latest avatar/name
      // But for now, we use Auth profile or fetch from Firestore if needed.
      // Let's try to fetch user profile from Firestore to be safe.
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      final String userName = userData?['name'] ?? user.displayName ?? 'User';
      final String? userAvatar = userData?['avatarUrl'] ?? user.photoURL;

      final commentData = {
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
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Fetch moments (optional helper)
  Future<List<MomentModel>> getMoments({int limit = 20}) async {
    final userId = _auth.currentUser?.uid;

    final querySnapshot = await _momentsCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    // Note: determining isLiked requires checking subcollections or a separate query.
    // For efficiency, we might need a separate index or strategy, but here we do simple check.

    if (userId == null) {
      return querySnapshot.docs
          .map((doc) => MomentModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id,
              isLiked: false))
          .toList();
    }

    final futures = querySnapshot.docs.map((doc) async {
      final likeDoc = await doc.reference.collection('likes').doc(userId).get();
      return MomentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id,
          isLiked: likeDoc.exists);
    });

    return Future.wait(futures);
  }
}

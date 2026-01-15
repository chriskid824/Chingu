import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _momentsCollection => _firestore.collection('moments');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Toggle like for a moment
  Future<void> toggleLike(String momentId, String userId) async {
    final momentRef = _momentsCollection.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final momentSnapshot = await transaction.get(momentRef);
        if (!momentSnapshot.exists) {
          throw Exception('Moment does not exist');
        }

        final likeSnapshot = await transaction.get(likeRef);

        if (likeSnapshot.exists) {
            // Unlike
            transaction.delete(likeRef);
            transaction.update(momentRef, {
                'likeCount': FieldValue.increment(-1)
            });
        } else {
            // Like
            transaction.set(likeRef, {
                'createdAt': FieldValue.serverTimestamp(),
            });
            transaction.update(momentRef, {
                'likeCount': FieldValue.increment(1)
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
  Future<void> addComment(String momentId, String userId, String content) async {
    if (content.trim().isEmpty) return;

    try {
      // Fetch user details first
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? 'Unknown';
      final userAvatar = userData['avatarUrl'];

      final commentRef = _momentsCollection.doc(momentId).collection('comments').doc();
      final momentRef = _momentsCollection.doc(momentId);

      await _firestore.runTransaction((transaction) async {
        // Create comment
        transaction.set(commentRef, {
          'userId': userId,
          'userName': userName,
          'userAvatar': userAvatar,
          'content': content.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update comment count
        transaction.update(momentRef, {
          'commentCount': FieldValue.increment(1),
        });
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/models/comment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _momentsCollection => _firestore.collection('moments');

  /// Like a moment
  Future<void> likeMoment(String momentId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final momentRef = _momentsCollection.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(user.uid);

    return _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      if (likeDoc.exists) {
        return; // Already liked
      }

      transaction.set(likeRef, {
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(momentRef, {
        'likeCount': FieldValue.increment(1),
      });
    });
  }

  /// Unlike a moment
  Future<void> unlikeMoment(String momentId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final momentRef = _momentsCollection.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(user.uid);

    return _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      if (!likeDoc.exists) {
        return; // Not liked
      }

      transaction.delete(likeRef);

      transaction.update(momentRef, {
        'likeCount': FieldValue.increment(-1),
      });
    });
  }

  /// Get comments stream
  Stream<List<CommentModel>> getCommentsStream(String momentId) {
    return _momentsCollection
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommentModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Add a comment
  Future<void> addComment(String momentId, String content) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    if (content.trim().isEmpty) return;

    final commentRef = _momentsCollection.doc(momentId).collection('comments').doc();
    final momentRef = _momentsCollection.doc(momentId);

    final comment = CommentModel(
      id: commentRef.id,
      momentId: momentId,
      userId: user.uid,
      userName: user.displayName ?? 'User',
      userAvatar: user.photoURL,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    return _firestore.runTransaction((transaction) async {
      transaction.set(commentRef, comment.toMap());

      transaction.update(momentRef, {
        'commentCount': FieldValue.increment(1),
      });
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/models/comment_model.dart';

class MomentService {
  static final MomentService _instance = MomentService._internal();

  factory MomentService() => _instance;

  MomentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _momentsRef => _firestore.collection('moments');

  // Like/Unlike moment
  Future<void> likeMoment(String momentId, String userId) async {
    final docRef = _momentsRef.doc(momentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final likes = List<String>.from(data['likes'] ?? []);

      if (likes.contains(userId)) {
        // Unlike
        transaction.update(docRef, {
          'likes': FieldValue.arrayRemove([userId]),
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        transaction.update(docRef, {
          'likes': FieldValue.arrayUnion([userId]),
          'likeCount': FieldValue.increment(1),
        });
      }
    });
  }

  // Get comments stream
  Stream<List<CommentModel>> getCommentsStream(String momentId) {
    return _momentsRef
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

  // Add comment
  Future<void> addComment(String momentId, CommentModel comment) async {
    final momentRef = _momentsRef.doc(momentId);
    final commentRef = momentRef.collection('comments').doc();

    // Create new comment with generated ID and current time
    final newComment = CommentModel(
      id: commentRef.id,
      momentId: momentId,
      userId: comment.userId,
      userName: comment.userName,
      userAvatar: comment.userAvatar,
      content: comment.content,
      createdAt: DateTime.now(),
    );

    await _firestore.runTransaction((transaction) async {
      transaction.set(commentRef, newComment.toMap());
      transaction.update(momentRef, {
        'commentCount': FieldValue.increment(1),
      });
    });
  }
}

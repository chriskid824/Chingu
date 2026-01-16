import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/models/comment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore;

  MomentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _momentsRef => _firestore.collection('moments');

  // Like a moment
  Future<void> likeMoment(String momentId, String userId) async {
    final momentRef = _momentsRef.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(likeRef);
      if (!snapshot.exists) {
        transaction.set(likeRef, {'createdAt': DateTime.now().millisecondsSinceEpoch});
        transaction.update(momentRef, {'likeCount': FieldValue.increment(1)});
      }
    });
  }

  // Unlike a moment
  Future<void> unlikeMoment(String momentId, String userId) async {
    final momentRef = _momentsRef.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(likeRef);
      if (snapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(momentRef, {'likeCount': FieldValue.increment(-1)});
      }
    });
  }

  // Check if liked
  Future<bool> hasLiked(String momentId, String userId) async {
    final doc = await _momentsRef.doc(momentId).collection('likes').doc(userId).get();
    return doc.exists;
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
        return CommentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Add comment
  Future<void> addComment(String momentId, String userId, String userName, String? userAvatar, String content) async {
    final momentRef = _momentsRef.doc(momentId);
    final commentsRef = momentRef.collection('comments');

    final comment = {
      'momentId': momentId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    await _firestore.runTransaction((transaction) async {
      final newCommentRef = commentsRef.doc();
      transaction.set(newCommentRef, comment);
      transaction.update(momentRef, {'commentCount': FieldValue.increment(1)});
    });
  }
}

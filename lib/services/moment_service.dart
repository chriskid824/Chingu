import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/comment_model.dart';
import 'package:chingu/models/user_model.dart';

class MomentService {
  final FirebaseFirestore _firestore;

  MomentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _momentsRef => _firestore.collection('moments');

  Future<void> likeMoment(String momentId, String userId) async {
    final momentRef = _momentsRef.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      if (!likeDoc.exists) {
        transaction.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
        transaction.update(momentRef, {
          'likeCount': FieldValue.increment(1),
        });
      }
    });
  }

  Future<void> unlikeMoment(String momentId, String userId) async {
    final momentRef = _momentsRef.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      if (likeDoc.exists) {
        transaction.delete(likeRef);
        transaction.update(momentRef, {
          'likeCount': FieldValue.increment(-1),
        });
      }
    });
  }

  Stream<List<CommentModel>> getComments(String momentId) {
    return _momentsRef
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addComment(String momentId, String content, UserModel currentUser) async {
    final momentRef = _momentsRef.doc(momentId);
    final commentsRef = momentRef.collection('comments');

    final commentData = {
      'momentId': momentId,
      'userId': currentUser.uid,
      'userName': currentUser.name,
      'userAvatar': currentUser.avatarUrl,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.runTransaction((transaction) async {
      transaction.set(commentsRef.doc(), commentData);
      transaction.update(momentRef, {
        'commentCount': FieldValue.increment(1),
      });
    });
  }
}

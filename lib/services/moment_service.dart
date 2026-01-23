import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _momentsRef => _firestore.collection('moments');

  Future<List<MomentModel>> fetchMoments({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? currentUserId,
  }) async {
    try {
      Query query = _momentsRef.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      List<MomentModel> moments = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        bool isLiked = false;

        if (currentUserId != null) {
          final likeDoc = await _momentsRef
              .doc(doc.id)
              .collection('likes')
              .doc(currentUserId)
              .get();
          isLiked = likeDoc.exists;
        }

        moments.add(MomentModel.fromMap(data, doc.id).copyWith(isLiked: isLiked));
      }

      return moments;
    } catch (e) {
      throw Exception('Failed to fetch moments: $e');
    }
  }

  Future<void> toggleLike(String momentId, String userId) async {
    final momentRef = _momentsRef.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final likeDoc = await transaction.get(likeRef);

        if (likeDoc.exists) {
            // Already liked, so unlike
            transaction.delete(likeRef);
            transaction.update(momentRef, {
                'likeCount': FieldValue.increment(-1),
            });
        } else {
            // Not liked, so like
            transaction.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
            transaction.update(momentRef, {
                'likeCount': FieldValue.increment(1),
            });
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String momentId) async {
    try {
      final snapshot = await _momentsRef
          .doc(momentId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          if (data['createdAt'] is Timestamp) {
              data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
          }
          return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get comments: $e');
    }
  }

  Future<void> addComment(String momentId, String userId, String content, String userName, String? userAvatar) async {
     try {
       await _firestore.runTransaction((transaction) async {
         final momentRef = _momentsRef.doc(momentId);
         final commentRef = momentRef.collection('comments').doc();

         final commentData = {
           'userId': userId,
           'userName': userName,
           'userAvatar': userAvatar,
           'content': content,
           'createdAt': FieldValue.serverTimestamp(),
         };

         transaction.set(commentRef, commentData);
         transaction.update(momentRef, {
           'commentCount': FieldValue.increment(1),
         });
       });
     } catch (e) {
       throw Exception('Failed to add comment: $e');
     }
  }
}

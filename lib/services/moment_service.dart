import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _momentsCollection => _firestore.collection('moments');

  /// Fetches moments with pagination.
  /// Also checks if the current user has liked each moment.
  Future<List<MomentModel>> getMoments({
    required String currentUserId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _momentsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      final moments = <MomentModel>[];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Check if user liked this moment
        final likeDoc = await _momentsCollection
            .doc(doc.id)
            .collection('likes')
            .doc(currentUserId)
            .get();

        final isLiked = likeDoc.exists;

        moments.add(MomentModel.fromMap(data, doc.id, isLiked: isLiked));
      }

      return moments;
    } catch (e) {
      throw Exception('Failed to fetch moments: $e');
    }
  }

  /// Toggles the like status of a moment for a user.
  /// Returns the new like count and isLiked status.
  Future<Map<String, dynamic>> toggleLike(String momentId, String userId) async {
    final momentRef = _momentsCollection.doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    try {
      return await _firestore.runTransaction((transaction) async {
        final momentDoc = await transaction.get(momentRef);
        if (!momentDoc.exists) {
          throw Exception('Moment does not exist!');
        }

        final likeDoc = await transaction.get(likeRef);
        bool isLiked = likeDoc.exists;
        final momentData = momentDoc.data() as Map<String, dynamic>;
        int currentLikeCount = momentData.containsKey('likeCount')
             ? (momentData['likeCount'] ?? 0)
             : 0;

        if (isLiked) {
          // Unlike
          transaction.delete(likeRef);
          transaction.update(momentRef, {'likeCount': FieldValue.increment(-1)});
          currentLikeCount = (currentLikeCount - 1).clamp(0, 999999);
          isLiked = false;
        } else {
          // Like
          transaction.set(likeRef, {
            'likedAt': FieldValue.serverTimestamp(),
          });
          transaction.update(momentRef, {'likeCount': FieldValue.increment(1)});
          currentLikeCount += 1;
          isLiked = true;
        }

        return {
          'likeCount': currentLikeCount,
          'isLiked': isLiked,
        };
      });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Adds a comment to a moment.
  Future<void> addComment(String momentId, String userId, String content, String userName, String? userAvatar) async {
    if (content.trim().isEmpty) return;

    final momentRef = _momentsCollection.doc(momentId);
    final commentsRef = momentRef.collection('comments');

    try {
      await _firestore.runTransaction((transaction) async {
        // Add comment document
        final newCommentRef = commentsRef.doc();
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
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Fetches comments for a moment.
  Stream<List<Map<String, dynamic>>> getCommentsStream(String momentId) {
    return _momentsCollection
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Create a moment (for testing/seeding)
  Future<void> createMoment(MomentModel moment) async {
    await _momentsCollection.add(moment.toMap());
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/models.dart';
import 'package:chingu/services/storage_service.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  Future<void> createMoment({
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
    File? image,
  }) async {
    try {
      String? imageUrl;
      if (image != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'moments/$userId/$timestamp.jpg';
        final task = _storageService.uploadFile(image, path);
        await task;
        imageUrl = await _storageService.getDownloadUrl(path);
      }

      final moment = MomentModel(
        id: '', // Will be set by Firestore
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      // We need to convert MomentModel to Map, but MomentModel doesn't have toMap in the memory provided earlier.
      // I'll check if I need to add it or construct it manually.
      // Given the read_file of MomentModel, it didn't show toMap/fromMap.
      // I'll construct the map manually here.

      await _firestore.collection('moments').add({
        'userId': moment.userId,
        'userName': moment.userName,
        'userAvatar': moment.userAvatar,
        'content': moment.content,
        'imageUrl': moment.imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'commentCount': 0,
      });
    } catch (e) {
      throw Exception('Failed to create moment: $e');
    }
  }

  Stream<List<MomentModel>> getMomentsStream({String? userId}) {
    Query query = _firestore.collection('moments').orderBy('createdAt', descending: true);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    return query.snapshots().asyncMap((snapshot) async {
      final moments = <MomentModel>[];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Check if current user liked this moment
        // This is tricky in a stream without current user context passed in constantly or fetching separately.
        // For simplicity, we might default isLiked to false and update it later or fetch it here.
        // Let's assume we pass currentUserId if needed, but for now we'll just map the basic data.
        // Wait, MomentModel has isLiked. We need the current user ID to check the subcollection.

        // If we want isLiked to be accurate, we need the current user ID.
        // I'll add currentUserId as an optional param to this method if we want to check likes.

        moments.add(_mapToMoment(doc.id, data));
      }
      return moments;
    });
  }

  // Improved version with like status
  Stream<List<MomentModel>> getMomentsStreamWithLikeStatus(String currentUserId, {String? targetUserId}) {
    Query query = _firestore.collection('moments').orderBy('createdAt', descending: true);

    if (targetUserId != null) {
      query = query.where('userId', isEqualTo: targetUserId);
    }

    return query.snapshots().asyncMap((snapshot) async {
      final moments = <MomentModel>[];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final momentId = doc.id;

        bool isLiked = false;
        try {
          final likeDoc = await _firestore
              .collection('moments')
              .doc(momentId)
              .collection('likes')
              .doc(currentUserId)
              .get();
          isLiked = likeDoc.exists;
        } catch (_) {
          // ignore error
        }

        moments.add(_mapToMoment(doc.id, data, isLiked: isLiked));
      }
      return moments;
    });
  }

  MomentModel _mapToMoment(String id, Map<String, dynamic> data, {bool isLiked = false}) {
    return MomentModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'],
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      isLiked: isLiked,
    );
  }

  Future<void> toggleLike(String momentId, String userId, bool currentStatus) async {
    final momentRef = _firestore.collection('moments').doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    return _firestore.runTransaction((transaction) async {
      final momentSnapshot = await transaction.get(momentRef);
      if (!momentSnapshot.exists) return;

      if (currentStatus) {
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
  }

  Future<void> addComment(String momentId, CommentModel comment) async {
    final momentRef = _firestore.collection('moments').doc(momentId);
    final commentRef = momentRef.collection('comments').doc(); // Auto-id

    final batch = _firestore.batch();
    batch.set(commentRef, comment.toMap());
    batch.update(momentRef, {
      'commentCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Stream<List<CommentModel>> getCommentsStream(String momentId) {
    return _firestore
        .collection('moments')
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CommentModel.fromMap(doc.data(), doc.id)).toList();
    });
  }
}

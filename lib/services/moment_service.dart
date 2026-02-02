import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/services/storage_service.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  /// Create a new moment
  Future<void> createMoment({
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
    File? imageFile,
  }) async {
    String? imageUrl;

    if (imageFile != null) {
      final String fileName = 'moments/${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      final task = _storageService.uploadFile(imageFile, fileName);
      final snapshot = await task;
      imageUrl = await snapshot.ref.getDownloadURL();
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

    await _firestore.collection('moments').add(moment.toMap());
  }

  /// Get moments
  Future<List<MomentModel>> getMoments({
    String? userId,
    String? currentUserId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore.collection('moments').orderBy('createdAt', descending: true);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    final moments = snapshot.docs.map((doc) => MomentModel.fromFirestore(doc)).toList();

    if (currentUserId != null) {
      // Check if liked by current user
      final momentsWithLikeStatus = await Future.wait(moments.map((moment) async {
        final likeDoc = await _firestore
            .collection('moments')
            .doc(moment.id)
            .collection('likes')
            .doc(currentUserId)
            .get();
        return moment.copyWith(isLiked: likeDoc.exists);
      }));
      return momentsWithLikeStatus;
    }

    return moments;
  }

  /// Toggle like
  Future<bool> toggleLike(String momentId, String userId) async {
    final momentRef = _firestore.collection('moments').doc(momentId);
    final likeRef = momentRef.collection('likes').doc(userId);

    return await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      final momentDoc = await transaction.get(momentRef);

      if (!momentDoc.exists) {
        throw Exception('Moment does not exist');
      }

      final currentLikeCount = momentDoc.data()?['likeCount'] ?? 0;
      bool isLiked = likeDoc.exists;

      if (isLiked) {
        transaction.delete(likeRef);
        transaction.update(momentRef, {'likeCount': currentLikeCount - 1});
        return false;
      } else {
        transaction.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        transaction.update(momentRef, {'likeCount': currentLikeCount + 1});
        return true;
      }
    });
  }

  /// Delete moment
  Future<void> deleteMoment(String momentId) async {
    await _firestore.collection('moments').doc(momentId).delete();
  }
}

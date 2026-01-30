import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/services/storage_service.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  CollectionReference get _momentsRef => _firestore.collection('moments');

  /// Create a new moment
  Future<void> createMoment({
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
    File? imageFile,
  }) async {
    try {
      final docRef = _momentsRef.doc();
      String? imageUrl;

      if (imageFile != null) {
        // Upload image
        final path = 'moments/${docRef.id}.jpg';
        await _storageService.uploadFile(imageFile, path);
        imageUrl = await _storageService.getDownloadUrl(path);
      }

      final moment = MomentModel(
        id: docRef.id,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        likeCount: 0,
        commentCount: 0,
        isLiked: false,
      );

      // Convert MomentModel to Map.
      // Note: MomentModel might not have toMap(), need to check or create one manually here if missing.
      // I'll assume I need to do it manually since I only saw copyWith/props in the read_file output.
      await docRef.set({
        'id': moment.id,
        'userId': moment.userId,
        'userName': moment.userName,
        'userAvatar': moment.userAvatar,
        'content': moment.content,
        'imageUrl': moment.imageUrl,
        'createdAt': FieldValue.serverTimestamp(), // Use server timestamp
        'likeCount': moment.likeCount,
        'commentCount': moment.commentCount,
        'likes': [], // Array of userIds who liked
      });
    } catch (e) {
      throw Exception('Failed to create moment: $e');
    }
  }

  /// Get moments for a specific user
  Stream<List<MomentModel>> getUserMomentsStream(String userId, String viewerId) {
    return _momentsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Handle Timestamp to DateTime conversion
        DateTime createdAt;
        if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } else {
          createdAt = DateTime.now();
        }

        final List likes = (data['likes'] as List?) ?? [];
        final bool isLiked = likes.contains(viewerId);

        return MomentModel(
          id: data['id'] ?? doc.id,
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? 'Unknown',
          userAvatar: data['userAvatar'],
          content: data['content'] ?? '',
          imageUrl: data['imageUrl'],
          createdAt: createdAt,
          likeCount: data['likeCount'] ?? 0,
          commentCount: data['commentCount'] ?? 0,
          isLiked: isLiked,
        );
      }).toList();
    });
  }

  /// Delete a moment
  Future<void> deleteMoment(String momentId) async {
    try {
      await _momentsRef.doc(momentId).delete();
      // Optionally delete image from storage if we want to be clean,
      // but StorageService doesn't have delete exposed yet.
      // Ignoring for "simple" scope.
    } catch (e) {
      throw Exception('Failed to delete moment: $e');
    }
  }

  /// Toggle like on a moment
  Future<void> toggleLike(String momentId, String userId) async {
    final docRef = _momentsRef.doc(momentId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final List likes = data['likes'] ?? [];
      int likeCount = data['likeCount'] ?? 0;

      if (likes.contains(userId)) {
        // Unlike
        likes.remove(userId);
        likeCount = (likeCount - 1).clamp(0, 999999);
      } else {
        // Like
        likes.add(userId);
        likeCount++;
      }

      transaction.update(docRef, {
        'likes': likes,
        'likeCount': likeCount,
      });
    });
  }
}

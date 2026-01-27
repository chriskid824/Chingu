import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/services/storage_service.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  CollectionReference get _momentsCollection => _firestore.collection('moments');

  /// Create a new moment
  Future<void> createMoment({
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
    File? imageFile,
  }) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'moments/$userId/$timestamp.jpg';
        final task = _storageService.uploadFile(imageFile, path);
        await task;
        imageUrl = await _storageService.getDownloadUrl(path);
      }

      final docRef = _momentsCollection.doc();
      final moment = MomentModel(
        id: docRef.id,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      // Convert to map and ensure createdAt is a Timestamp for Firestore
      final Map<String, dynamic> data = {
        'id': moment.id,
        'userId': moment.userId,
        'userName': moment.userName,
        'userAvatar': moment.userAvatar,
        'content': moment.content,
        'imageUrl': moment.imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': moment.likeCount,
        'commentCount': moment.commentCount,
        'isLiked': moment.isLiked,
      };

      await docRef.set(data);
    } catch (e) {
      throw Exception('Failed to create moment: $e');
    }
  }

  /// Get moments (ordered by createdAt desc)
  Future<List<MomentModel>> getMoments({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _momentsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Handle Timestamp to DateTime conversion if needed
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] == null) {
           data['createdAt'] = DateTime.now(); // Fallback
        }
        return MomentModel(
          id: data['id'] ?? doc.id,
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? 'Unknown',
          userAvatar: data['userAvatar'],
          content: data['content'] ?? '',
          imageUrl: data['imageUrl'],
          createdAt: data['createdAt'] as DateTime,
          likeCount: data['likeCount'] ?? 0,
          commentCount: data['commentCount'] ?? 0,
          isLiked: data['isLiked'] ?? false,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get moments: $e');
    }
  }

  /// Delete a moment
  Future<void> deleteMoment(String momentId) async {
    try {
      await _momentsCollection.doc(momentId).delete();
      // Note: We might want to delete the image from storage as well,
      // but we need the image path for that.
      // For now, we just delete the document.
    } catch (e) {
      throw Exception('Failed to delete moment: $e');
    }
  }
}

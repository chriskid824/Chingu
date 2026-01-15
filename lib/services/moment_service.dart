import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/services/storage_service.dart';

class MomentService {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  MomentService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? StorageService();

  CollectionReference get _momentsCollection => _firestore.collection('moments');

  /// Create a new moment
  Future<void> createMoment(MomentModel moment, File? imageFile) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        // Create a unique path for the image
        final String path = 'moments/${moment.userId}/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        final task = _storageService.uploadFile(imageFile, path);

        // Wait for upload to complete
        await task;

        // Get the download URL
        imageUrl = await _storageService.getDownloadUrl(path);
      }

      final newMoment = moment.copyWith(
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      // We use the ID from the model if provided, otherwise let Firestore generate one
      // But MomentModel seems to require ID in constructor.
      // Usually we generate ID before saving or let Firestore generate it.
      // If the passed moment has an empty ID, we can generate a new doc ref.

      DocumentReference docRef;
      if (moment.id.isEmpty) {
        docRef = _momentsCollection.doc();
      } else {
        docRef = _momentsCollection.doc(moment.id);
      }

      final momentToSave = newMoment.copyWith(id: docRef.id);

      // Convert to map. MomentModel doesn't have toMap() in the snippet I saw?
      // Wait, I need to check if MomentModel has toMap/fromMap.
      // The snippet I read earlier only showed properties and copyWith.
      // I need to double check MomentModel content.
      // If it doesn't have toMap/fromMap, I need to add them or handle serialization here.

      // Assuming I need to add serialization or do it manually.
      // I'll check the file content again carefully.

      await docRef.set(_momentToMap(momentToSave));

    } catch (e) {
      throw Exception('Failed to create moment: $e');
    }
  }

  /// Get moments for a specific user
  Stream<List<MomentModel>> getUserMomentsStream(String userId) {
    return _momentsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _momentFromMap(data, doc.id);
      }).toList();
    });
  }

  /// Get all moments (feed) - Optional, for future use
  Stream<List<MomentModel>> getMomentsFeedStream() {
    return _momentsCollection
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _momentFromMap(data, doc.id);
      }).toList();
    });
  }

  /// Delete a moment
  Future<void> deleteMoment(String momentId) async {
    try {
      await _momentsCollection.doc(momentId).delete();
    } catch (e) {
      throw Exception('Failed to delete moment: $e');
    }
  }

  // Helper methods for serialization if Model doesn't have them
  Map<String, dynamic> _momentToMap(MomentModel moment) {
    return {
      'userId': moment.userId,
      'userName': moment.userName,
      'userAvatar': moment.userAvatar,
      'content': moment.content,
      'imageUrl': moment.imageUrl,
      'createdAt': Timestamp.fromDate(moment.createdAt),
      'likeCount': moment.likeCount,
      'commentCount': moment.commentCount,
      // 'isLiked' is not stored in Firestore main doc typically
    };
  }

  MomentModel _momentFromMap(Map<String, dynamic> data, String id) {
    return MomentModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'],
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      isLiked: false, // Default to false, logic to check liked status would be separate
    );
  }
}

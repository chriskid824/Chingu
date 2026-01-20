import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/services/storage_service.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  CollectionReference get _momentsCollection => _firestore.collection('moments');

  /// Creates a new moment.
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
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
        final String path = 'moments/$fileName';
        final task = _storageService.uploadFile(imageFile, path);
        final snapshot = await task;
        imageUrl = await snapshot.ref.getDownloadURL();
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

      await docRef.set(moment.toMap());
    } catch (e) {
      throw Exception('Failed to create moment: $e');
    }
  }

  /// Retrieves a list of moments.
  /// If [userId] is provided, filters by that user.
  Future<List<MomentModel>> getMoments({String? userId, int limit = 20}) async {
    try {
      Query query = _momentsCollection.orderBy('createdAt', descending: true).limit(limit);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => MomentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get moments: $e');
    }
  }

  /// Deletes a moment by its ID.
  Future<void> deleteMoment(String momentId) async {
      try {
          await _momentsCollection.doc(momentId).delete();
      } catch (e) {
          throw Exception('Failed to delete moment: $e');
      }
  }
}

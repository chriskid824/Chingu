import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/storage_service.dart';
import 'package:chingu/models/moment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  Future<void> createMoment({
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
    File? imageFile,
  }) async {
    String? imageUrl;

    if (imageFile != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'moments/${userId}_$timestamp.jpg';

      final task = _storageService.uploadFile(imageFile, path);
      await task;

      imageUrl = await _storageService.getDownloadUrl(path);
    }

    final momentData = {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'commentCount': 0,
    };

    await _firestore.collection('moments').add(momentData);
  }

  Stream<List<MomentModel>> getMoments(String userId) {
    return _firestore
        .collection('moments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MomentModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> deleteMoment(String momentId) {
    return _firestore.collection('moments').doc(momentId).delete();
  }
}

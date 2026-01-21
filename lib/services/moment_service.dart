import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/moment_model.dart';
import 'storage_service.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  Future<void> createMoment(MomentModel moment, File? imageFile) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        final path = 'moments/${moment.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _storageService.uploadFile(imageFile, path);
        imageUrl = await _storageService.getDownloadUrl(path);
      }

      final momentToSave = moment.copyWith(
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('moments').add(momentToSave.toMap());
    } catch (e) {
      throw Exception('Failed to create moment: $e');
    }
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

  Future<void> deleteMoment(String momentId) async {
    try {
      await _firestore.collection('moments').doc(momentId).delete();
    } catch (e) {
      throw Exception('Failed to delete moment: $e');
    }
  }
}

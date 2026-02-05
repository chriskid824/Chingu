import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/moment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'moments';

  // Get moments stream
  Stream<List<MomentModel>> getMoments() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MomentModel.fromFirestore(doc)).toList();
    });
  }

  // Create moment
  Future<void> createMoment({
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
    File? imageFile,
  }) async {
    String? imageUrl;

    if (imageFile != null) {
      final ref = _storage
          .ref()
          .child('moment_images')
          .child('${DateTime.now().millisecondsSinceEpoch}_$userId.jpg');

      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    final moment = MomentModel(
      id: '', // Firestore will generate
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(_collection).add(moment.toMap());
  }

  // Delete moment
  Future<void> deleteMoment(String momentId, String? imageUrl) async {
      await _firestore.collection(_collection).doc(momentId).delete();

      if (imageUrl != null) {
          try {
              final ref = _storage.refFromURL(imageUrl);
              await ref.delete();
          } catch (e) {
              print('Error deleting image: $e');
          }
      }
  }
}

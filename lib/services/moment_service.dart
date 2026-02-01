import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/moment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
        final ref = _storage
            .ref()
            .child('moments/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      final docRef = _firestore.collection('moments').doc();

      final moment = MomentModel(
        id: docRef.id,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await docRef.set(moment.toJson());
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
      return snapshot.docs.map((doc) => MomentModel.fromJson(doc.data())).toList();
    });
  }

  Future<void> deleteMoment(String momentId) async {
    try {
      final doc = await _firestore.collection('moments').doc(momentId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['imageUrl'] != null) {
          try {
            await _storage.refFromURL(data['imageUrl']).delete();
          } catch (e) {
            // Ignore storage delete errors
            print('Error deleting image: $e');
          }
        }
        await _firestore.collection('moments').doc(momentId).delete();
      }
    } catch (e) {
      throw Exception('Failed to delete moment: $e');
    }
  }
}

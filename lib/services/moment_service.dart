import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/moment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'moments';

  // Upload images and return URLs
  Future<List<String>> _uploadImages(List<File> images, String userId) async {
    List<String> urls = [];
    for (var image in images) {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      Reference ref = _storage.ref().child('user_moments/$userId/$fileName');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> createMoment(MomentModel moment, List<File> images) async {
    try {
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await _uploadImages(images, moment.userId);
      }

      MomentModel newMoment = moment.copyWith(
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_collection).add(newMoment.toMap());
    } catch (e) {
      throw Exception('Failed to create moment: $e');
    }
  }

  Stream<List<MomentModel>> getMoments(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MomentModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> deleteMoment(String momentId) async {
    try {
      // Get moment data to find image URLs
      final doc = await _firestore.collection(_collection).doc(momentId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> urls = data['imageUrls'] ?? [];

        // Delete images from storage
        for (final url in urls) {
          try {
            if (url is String && url.isNotEmpty) {
              await _storage.refFromURL(url).delete();
            }
          } catch (e) {
            // Log error but continue deleting other images and the document
            print('Error deleting image: $e');
          }
        }
      }

      await _firestore.collection(_collection).doc(momentId).delete();
    } catch (e) {
      throw Exception('Failed to delete moment: $e');
    }
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:flutter/foundation.dart';

class MomentsService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  MomentsService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference get _momentsCollection => _firestore.collection('moments');

  /// Creates a new moment with text content and optional images.
  Future<void> createMoment({
    required String userId,
    required String content,
    List<File>? images,
  }) async {
    try {
      List<String> imageUrls = [];

      // Upload images if provided
      if (images != null && images.isNotEmpty) {
        for (var i = 0; i < images.length; i++) {
          final file = images[i];
          final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final Reference ref = _storage.ref().child('moments/$userId/$fileName');

          final UploadTask uploadTask = ref.putFile(file);
          final TaskSnapshot snapshot = await uploadTask;
          final String downloadUrl = await snapshot.ref.getDownloadURL();
          imageUrls.add(downloadUrl);
        }
      }

      final newMoment = MomentModel(
        id: '', // Firestore will generate ID
        userId: userId,
        content: content,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        likeCount: 0,
      );

      await _momentsCollection.add(newMoment.toMap());
    } catch (e) {
      throw Exception('Failed to create moment: $e');
    }
  }

  /// Retrieves moments for a specific user, ordered by creation time (newest first).
  Stream<List<MomentModel>> getUserMoments(String userId) {
    return _momentsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MomentModel.fromFirestore(doc)).toList();
    });
  }

  /// Deletes a moment and its associated images.
  Future<void> deleteMoment(String momentId) async {
    try {
      // 1. Get the moment data to find image URLs
      final docSnapshot = await _momentsCollection.doc(momentId).get();
      if (!docSnapshot.exists) return;

      final moment = MomentModel.fromFirestore(docSnapshot);

      // 2. Delete images from Storage
      // Note: This relies on the path structure being consistent or parsing the URL.
      // Since we store full URLs, we can try to get the reference from the URL.
      for (final url in moment.imageUrls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (e) {
          // Ignore error if image doesn't exist or deletion fails, proceed to delete document
          debugPrint('Failed to delete image $url: $e');
        }
      }

      // 3. Delete the document
      await _momentsCollection.doc(momentId).delete();
    } catch (e) {
      throw Exception('Failed to delete moment: $e');
    }
  }
}

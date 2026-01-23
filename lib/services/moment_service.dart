import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/moment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection reference
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
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storageRef = _storage
            .ref()
            .child('moments/$userId/$timestamp.jpg');

        await storageRef.putFile(imageFile);
        imageUrl = await storageRef.getDownloadURL();
      }

      final docRef = _momentsRef.doc();
      final now = DateTime.now();

      final moment = MomentModel(
        id: docRef.id,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
        imageUrl: imageUrl,
        createdAt: now,
        likeCount: 0,
        commentCount: 0,
        isLiked: false,
      );

      final data = moment.toMap();
      data['likedBy'] = []; // Initialize empty array for likes

      await docRef.set(data);

    } catch (e) {
      print('Error creating moment: $e');
      rethrow;
    }
  }

  /// Get moments stream for a specific user
  Stream<List<MomentModel>> getMomentsStream(String userId, String currentUserId) {
    return _momentsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MomentModel.fromFirestore(doc, currentUserId: currentUserId);
      }).toList();
    });
  }

  /// Toggle like status
  Future<void> toggleLike(String momentId, String userId) async {
    final docRef = _momentsRef.doc(momentId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception("Moment does not exist!");
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);

      if (likedBy.contains(userId)) {
        transaction.update(docRef, {
          'likedBy': FieldValue.arrayRemove([userId])
        });
      } else {
        transaction.update(docRef, {
          'likedBy': FieldValue.arrayUnion([userId])
        });
      }
    });
  }

  /// Delete a moment
  Future<void> deleteMoment(String momentId) async {
    await _momentsRef.doc(momentId).delete();
  }
}

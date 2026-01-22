import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/moment_model.dart';

class MomentService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  MomentService({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Collection reference
  CollectionReference get _momentsRef => _firestore.collection('moments');

  // Fetch moments for a specific user
  Stream<List<MomentModel>> fetchMoments(String userId) {
    return _momentsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MomentModel(
          id: doc.id,
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? 'Unknown',
          userAvatar: data['userAvatar'],
          content: data['content'] ?? '',
          imageUrl: data['imageUrl'],
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          likeCount: data['likeCount'] ?? 0,
          commentCount: data['commentCount'] ?? 0,
          isLiked: false, // This would require a separate subcollection query or field
        );
      }).toList();
    });
  }

  // Create a new moment
  Future<void> createMoment(MomentModel moment, File? imageFile) async {
    String? imageUrl;

    if (imageFile != null) {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage
          .ref()
          .child('user_moments')
          .child(moment.userId)
          .child(fileName);

      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
    }

    await _momentsRef.add({
      'userId': moment.userId,
      'userName': moment.userName,
      'userAvatar': moment.userAvatar,
      'content': moment.content,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'commentCount': 0,
    });
  }

  // Like a moment (Simple increment for now, realistic app would track users who liked)
  Future<void> likeMoment(String momentId) async {
    await _momentsRef.doc(momentId).update({
      'likeCount': FieldValue.increment(1),
    });
  }

  // Delete a moment
  Future<void> deleteMoment(String momentId) async {
    final docSnapshot = await _momentsRef.doc(momentId).get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      final imageUrl = data['imageUrl'] as String?;

      if (imageUrl != null) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          // Ignore error if image deletion fails (e.g. file not found)
          print('Error deleting image: $e');
        }
      }

      await _momentsRef.doc(momentId).delete();
    }
  }
}

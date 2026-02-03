import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/moment_model.dart';
import '../models/user_model.dart';

class MomentService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  MomentService({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Future<void> createMoment({
    required UserModel user,
    String? textContent,
    List<XFile> images = const [],
  }) async {
    List<String> imageUrls = [];

    for (var image in images) {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      Reference ref = _storage.ref().child('moment_images/${user.uid}/$fileName');

      try {
         await ref.putFile(File(image.path));
         String downloadUrl = await ref.getDownloadURL();
         imageUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading image: $e');
        rethrow;
      }
    }

    MomentModel moment = MomentModel(
      id: '', // Firestore generates this
      userId: user.uid,
      userName: user.name,
      userAvatar: user.avatarUrl,
      textContent: textContent,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('moments').add(moment.toMap());
  }

  Stream<List<MomentModel>> getMoments(String userId) {
    return _firestore
        .collection('moments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MomentModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> deleteMoment(String momentId) async {
    try {
      final doc = await _firestore.collection('moments').doc(momentId).get();
      if (doc.exists) {
        final moment = MomentModel.fromFirestore(doc);
        for (var url in moment.imageUrls) {
          try {
            await _storage.refFromURL(url).delete();
          } catch (e) {
            print('Error deleting image: $e');
          }
        }
      }
      await _firestore.collection('moments').doc(momentId).delete();
    } catch (e) {
      print('Error deleting moment: $e');
      rethrow;
    }
  }
}

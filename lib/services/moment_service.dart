import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/services/storage_service.dart';

class MomentService {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  MomentService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? StorageService();

  /// Creates a new moment.
  /// If [imageFile] is provided, it uploads the image first.
  Future<void> createMoment({
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
    File? imageFile,
  }) async {
    String? imageUrl;

    if (imageFile != null) {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String path = 'moments/$userId/$timestamp.jpg';
      await _storageService.uploadFile(imageFile, path);
      imageUrl = await _storageService.getDownloadUrl(path);
    }

    final moment = MomentModel(
      id: '', // Firestore will generate this
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('moments').add(moment.toMap());
  }

  /// Gets a stream of all moments, ordered by creation time descending.
  /// Optionally filters by userId.
  Stream<List<MomentModel>> getMomentsStream({String? userId}) {
    Query query = _firestore.collection('moments').orderBy('createdAt', descending: true);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MomentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Deletes a moment.
  Future<void> deleteMoment(String momentId) async {
    await _firestore.collection('moments').doc(momentId).delete();
  }
}

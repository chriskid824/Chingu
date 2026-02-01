import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FeedbackService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Future<void> submitFeedback(FeedbackModel feedback, List<File>? images) async {
    List<String> imageUrls = [];

    if (images != null && images.isNotEmpty) {
      for (var image in images) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
        Reference ref = _storage.ref().child('feedback_images/${feedback.id}/$fileName');
        UploadTask uploadTask = ref.putFile(image);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
    }

    FeedbackModel feedbackWithImages = feedback.copyWith(imageUrls: imageUrls);
    await _firestore.collection('feedback').doc(feedback.id).set(feedbackWithImages.toMap());
  }
}

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:uuid/uuid.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _momentsCollection => _firestore.collection('moments');

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
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference ref = _storage.ref().child('moments/$userId/$fileName');
        final UploadTask uploadTask = ref.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      final String id = const Uuid().v4();
      final moment = MomentModel(
        id: id,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        likeCount: 0,
        commentCount: 0,
        isLiked: false,
      );

      // We store likedUserIds in the document for simplicity
      final data = {
        'id': moment.id,
        'userId': moment.userId,
        'userName': moment.userName,
        'userAvatar': moment.userAvatar,
        'content': moment.content,
        'imageUrl': moment.imageUrl,
        'createdAt': moment.createdAt,
        'likeCount': moment.likeCount,
        'commentCount': moment.commentCount,
        'likedUserIds': [],
      };

      await _momentsCollection.doc(id).set(data);
    } catch (e) {
      throw Exception('Failed to create moment: $e');
    }
  }

  Stream<List<MomentModel>> getUserMomentsStream(String userId, String currentUserId) {
    return _momentsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final likedUserIds = List<String>.from(data['likedUserIds'] ?? []);

        // Convert timestamp to DateTime
        DateTime createdAt;
        if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
           createdAt = DateTime.parse(data['createdAt']);
        } else {
           createdAt = DateTime.now();
        }

        return MomentModel(
          id: data['id'],
          userId: data['userId'],
          userName: data['userName'],
          userAvatar: data['userAvatar'],
          content: data['content'],
          imageUrl: data['imageUrl'],
          createdAt: createdAt,
          likeCount: data['likeCount'] ?? 0,
          commentCount: data['commentCount'] ?? 0,
          isLiked: likedUserIds.contains(currentUserId),
        );
      }).toList();
    });
  }

  Future<void> deleteMoment(String momentId) async {
    try {
      // Get the moment to find the image URL
      final doc = await _momentsCollection.doc(momentId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final String? imageUrl = data['imageUrl'];

      if (imageUrl != null) {
        try {
          // Extract path from URL or store path in doc.
          // For now, attempting to delete from refFromURL.
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          // Ignore if image not found or delete fails
          print('Failed to delete image: $e');
        }
      }

      await _momentsCollection.doc(momentId).delete();
    } catch (e) {
      throw Exception('Failed to delete moment: $e');
    }
  }

  Future<void> toggleLike(String momentId, String userId) async {
    final docRef = _momentsCollection.doc(momentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Moment does not exist');
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final likedUserIds = List<String>.from(data['likedUserIds'] ?? []);
      int likeCount = data['likeCount'] ?? 0;

      if (likedUserIds.contains(userId)) {
        likedUserIds.remove(userId);
        likeCount = likeCount > 0 ? likeCount - 1 : 0;
      } else {
        likedUserIds.add(userId);
        likeCount += 1;
      }

      transaction.update(docRef, {
        'likedUserIds': likedUserIds,
        'likeCount': likeCount,
      });
    });
  }
}

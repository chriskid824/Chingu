import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/services/storage_service.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  CollectionReference get _momentsCollection => _firestore.collection('moments');

  /// 創建動態
  Future<void> createMoment({
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
    File? imageFile,
  }) async {
    try {
      String? imageUrl;

      // 如果有圖片，先上傳
      if (imageFile != null) {
        final String imagePath = 'moments/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadTask = _storageService.uploadFile(imageFile, imagePath);
        await uploadTask.whenComplete(() {});
        imageUrl = await _storageService.getDownloadUrl(imagePath);
      }

      // 使用 Firestore 自動生成的 ID
      final docRef = _momentsCollection.doc();
      final momentId = docRef.id;

      final moment = MomentModel(
        id: momentId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await docRef.set({
        'id': moment.id,
        'userId': moment.userId,
        'userName': moment.userName,
        'userAvatar': moment.userAvatar,
        'content': moment.content,
        'imageUrl': moment.imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': moment.likeCount,
        'commentCount': moment.commentCount,
        'isLiked': moment.isLiked,
      });

    } catch (e) {
      throw Exception('創建動態失敗: $e');
    }
  }

  /// 獲取特定用戶的動態
  Future<List<MomentModel>> getUserMoments(String userId) async {
    try {
      final querySnapshot = await _momentsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToMomentModel(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('獲取用戶動態失敗: $e');
    }
  }

  /// 獲取動態牆 (目前獲取所有)
  Future<List<MomentModel>> getMoments({int limit = 20, DocumentSnapshot? startAfter}) async {
    try {
      Query query = _momentsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToMomentModel(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('獲取動態失敗: $e');
    }
  }

  /// 刪除動態
  Future<void> deleteMoment(String momentId) async {
    try {
      await _momentsCollection.doc(momentId).delete();
      // TODO: 也應該刪除關聯的圖片
    } catch (e) {
      throw Exception('刪除動態失敗: $e');
    }
  }

  // 輔助方法：將 Map 轉換為 MomentModel
  MomentModel _mapToMomentModel(Map<String, dynamic> data, String id) {
    return MomentModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userAvatar: data['userAvatar'],
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      isLiked: data['isLiked'] ?? false,
    );
  }
}

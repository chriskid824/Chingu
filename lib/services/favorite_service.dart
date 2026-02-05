import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';

class FavoriteService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;

  FavoriteService({
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  /// 添加收藏
  Future<void> addFavorite(String userId, String targetUserId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(targetUserId)
          .set({
        'addedAt': FieldValue.serverTimestamp(),
        'targetUserId': targetUserId,
      });
    } catch (e) {
      throw Exception('添加收藏失敗: $e');
    }
  }

  /// 移除收藏
  Future<void> removeFavorite(String userId, String targetUserId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(targetUserId)
          .delete();
    } catch (e) {
      throw Exception('移除收藏失敗: $e');
    }
  }

  /// 檢查是否已收藏
  Future<bool> checkIsFavorite(String userId, String targetUserId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      throw Exception('檢查收藏失敗: $e');
    }
  }

  /// 獲取收藏列表
  Future<List<UserModel>> getFavorites(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) return [];

      final targetUserIds = snapshot.docs
          .map((doc) => doc.id)
          .toList();

      return await _firestoreService.getBatchUsers(targetUserIds);
    } catch (e) {
      throw Exception('獲取收藏列表失敗: $e');
    }
  }
}

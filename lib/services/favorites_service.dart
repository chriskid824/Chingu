import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // 获取用户的收藏集合引用
  CollectionReference _getFavoritesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  /// 切换收藏状态
  /// [userId] 当前用户ID
  /// [targetUserId] 目标用户ID
  Future<bool> toggleFavorite(String userId, String targetUserId) async {
    try {
      final docRef = _getFavoritesCollection(userId).doc(targetUserId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // 如果已收藏，则移除
        await docRef.delete();
        return false; // 返回 false 表示当前未收藏
      } else {
        // 如果未收藏，则添加
        await docRef.set({
          'createdAt': FieldValue.serverTimestamp(),
          'userId': targetUserId,
        });
        return true; // 返回 true 表示当前已收藏
      }
    } catch (e) {
      throw Exception('切換收藏狀態失敗: $e');
    }
  }

  /// 检查是否已收藏
  Future<bool> isFavorite(String userId, String targetUserId) async {
    try {
      final doc = await _getFavoritesCollection(userId).doc(targetUserId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// 获取收藏用户列表
  Future<List<UserModel>> getFavoriteUsers(String userId) async {
    try {
      final querySnapshot = await _getFavoritesCollection(userId)
          .orderBy('createdAt', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final List<String> userIds = querySnapshot.docs.map((doc) => doc.id).toList();

      return await _firestoreService.getBatchUsers(userIds);
    } catch (e) {
      throw Exception('獲取收藏列表失敗: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// 用戶封鎖服務 - 處理封鎖用戶相關邏輯
class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 獲取封鎖名單集合引用
  CollectionReference _blockedUsersRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('blocked_users');
  }

  /// 封鎖用戶
  ///
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 目標用戶 ID
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      await _blockedUsersRef(currentUserId).doc(targetUserId).set({
        'blockedAt': FieldValue.serverTimestamp(),
      });
      print('用戶 $currentUserId 已封鎖 $targetUserId');
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖
  ///
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 目標用戶 ID
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _blockedUsersRef(currentUserId).doc(targetUserId).delete();
      print('用戶 $currentUserId 已解除封鎖 $targetUserId');
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 獲取已封鎖的用戶 ID 列表
  ///
  /// [currentUserId] 當前用戶 ID
  Future<List<String>> getBlockedUserIds(String currentUserId) async {
    try {
      final snapshot = await _blockedUsersRef(currentUserId).get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('獲取封鎖名單失敗: $e');
      // 出錯時返回空列表，避免阻塞主流程
      return [];
    }
  }

  /// 檢查是否已封鎖某用戶
  ///
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 目標用戶 ID
  Future<bool> isBlocked(String currentUserId, String targetUserId) async {
    try {
      final doc = await _blockedUsersRef(currentUserId).doc(targetUserId).get();
      return doc.exists;
    } catch (e) {
      print('檢查封鎖狀態失敗: $e');
      return false;
    }
  }
}

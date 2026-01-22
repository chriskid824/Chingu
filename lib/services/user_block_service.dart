import 'package:cloud_firestore/cloud_firestore.dart';

class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // 獲取封鎖列表集合引用
  CollectionReference _getBlockedCollection(String currentUserId) {
    return _firestore.collection('users').doc(currentUserId).collection('blocked_users');
  }

  /// 封鎖用戶
  ///
  /// [currentUserId] 當前操作用戶 ID
  /// [blockedUserId] 被封鎖的用戶 ID
  Future<void> blockUser(String currentUserId, String blockedUserId) async {
    try {
      await _getBlockedCollection(currentUserId).doc(blockedUserId).set({
        'blockedAt': FieldValue.serverTimestamp(),
      });
      print('已封鎖用戶: $blockedUserId');
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖
  ///
  /// [currentUserId] 當前操作用戶 ID
  /// [blockedUserId] 要解除封鎖的用戶 ID
  Future<void> unblockUser(String currentUserId, String blockedUserId) async {
    try {
      await _getBlockedCollection(currentUserId).doc(blockedUserId).delete();
      print('已解除封鎖用戶: $blockedUserId');
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 檢查是否已封鎖某用戶
  ///
  /// [currentUserId] 當前操作用戶 ID
  /// [targetUserId] 目標用戶 ID
  Future<bool> isBlocked(String currentUserId, String targetUserId) async {
    try {
      final doc = await _getBlockedCollection(currentUserId).doc(targetUserId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('檢查封鎖狀態失敗: $e');
    }
  }

  /// 獲取所有已封鎖的用戶 ID 列表
  ///
  /// [currentUserId] 當前操作用戶 ID
  Future<List<String>> getBlockedUserIds(String currentUserId) async {
    try {
      final snapshot = await _getBlockedCollection(currentUserId).get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('獲取封鎖列表失敗: $e');
    }
  }
}

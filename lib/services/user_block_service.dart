import 'package:cloud_firestore/cloud_firestore.dart';

class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 封鎖用戶
  ///
  /// [currentUserId] 當前操作用戶 ID
  /// [blockedUserId] 被封鎖的用戶 ID
  /// [reason] 封鎖原因 (可選)
  Future<void> blockUser(String currentUserId, String blockedUserId, {String? reason}) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(blockedUserId)
          .set({
        'blockedUserId': blockedUserId,
        'blockedAt': FieldValue.serverTimestamp(),
        'reason': reason,
      });
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
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(blockedUserId)
          .delete();
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 檢查是否已封鎖
  ///
  /// [currentUserId] 當前操作用戶 ID
  /// [targetUserId] 目標用戶 ID
  Future<bool> isBlocked(String currentUserId, String targetUserId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      throw Exception('檢查封鎖狀態失敗: $e');
    }
  }

  /// 獲取所有封鎖的用戶 ID
  ///
  /// [currentUserId] 當前操作用戶 ID
  Future<List<String>> getBlockedUserIds(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('獲取封鎖名單失敗: $e');
    }
  }
}

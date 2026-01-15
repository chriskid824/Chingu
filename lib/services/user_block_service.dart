import 'package:cloud_firestore/cloud_firestore.dart';

/// 封鎖服務 - 處理用戶封鎖邏輯
///
/// 管理 `user_blocks` 集合，實現雙向封鎖（互相不可見）
class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _blocksCollection =>
      _firestore.collection('user_blocks');

  /// 封鎖用戶
  ///
  /// [currentUserId] 當前用戶 ID (發起封鎖者)
  /// [targetUserId] 目標用戶 ID (被封鎖者)
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      // 檢查是否已經封鎖，避免重複
      final isAlreadyBlocked = await isBlocked(currentUserId, targetUserId);
      if (isAlreadyBlocked) return;

      await _blocksCollection.add({
        'blockerId': currentUserId,
        'blockedId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖用戶
  ///
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 目標用戶 ID
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      final query = await _blocksCollection
          .where('blockerId', isEqualTo: currentUserId)
          .where('blockedId', isEqualTo: targetUserId)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 檢查是否已封鎖某用戶
  ///
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 目標用戶 ID
  Future<bool> isBlocked(String currentUserId, String targetUserId) async {
    try {
      final query = await _blocksCollection
          .where('blockerId', isEqualTo: currentUserId)
          .where('blockedId', isEqualTo: targetUserId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('檢查封鎖狀態失敗: $e');
    }
  }

  /// 獲取當前用戶封鎖的用戶 ID 列表
  ///
  /// [userId] 用戶 ID
  Future<List<String>> getBlockedUserIds(String userId) async {
    try {
      final query =
          await _blocksCollection.where('blockerId', isEqualTo: userId).get();

      return query.docs.map((doc) => doc['blockedId'] as String).toList();
    } catch (e) {
      throw Exception('獲取封鎖名單失敗: $e');
    }
  }

  /// 獲取封鎖了當前用戶的用戶 ID 列表
  ///
  /// [userId] 用戶 ID
  Future<List<String>> getBlockedByIds(String userId) async {
    try {
      final query =
          await _blocksCollection.where('blockedId', isEqualTo: userId).get();

      return query.docs.map((doc) => doc['blockerId'] as String).toList();
    } catch (e) {
      throw Exception('獲取被封鎖名單失敗: $e');
    }
  }

  /// 獲取所有相關的封鎖 ID（包括我封鎖的人和封鎖我的人）
  ///
  /// 用於過濾配對和搜尋結果，實現雙向不可見
  /// [userId] 用戶 ID
  Future<Set<String>> getBlockedAndBlockedByUserIds(String userId) async {
    try {
      final blockedUsers = await getBlockedUserIds(userId);
      final blockedByUsers = await getBlockedByIds(userId);

      return {...blockedUsers, ...blockedByUsers};
    } catch (e) {
      throw Exception('獲取雙向封鎖名單失敗: $e');
    }
  }
}

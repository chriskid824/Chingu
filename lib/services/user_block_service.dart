import 'package:cloud_firestore/cloud_firestore.dart';

/// 用戶封鎖服務 - 處理用戶封鎖邏輯
class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 封鎖記錄集合引用
  CollectionReference get _blocksCollection => _firestore.collection('user_blocks');

  /// 封鎖用戶
  ///
  /// [currentUserId] 執行封鎖的用戶 ID
  /// [targetUserId] 被封鎖的用戶 ID
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      // 檢查是否已封鎖，避免重複記錄
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
  /// [currentUserId] 執行解除封鎖的用戶 ID
  /// [targetUserId] 被解除封鎖的用戶 ID
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
      throw Exception('解除封鎖用戶失敗: $e');
    }
  }

  /// 檢查是否已封鎖某用戶
  ///
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 目標用戶 ID
  /// 返回 true 表示已封鎖
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

  /// 獲取被我封鎖的用戶 ID 列表
  ///
  /// [userId] 用戶 ID
  Future<List<String>> getBlockedUserIds(String userId) async {
    try {
      final query = await _blocksCollection
          .where('blockerId', isEqualTo: userId)
          .get();

      return query.docs.map((doc) => doc['blockedId'] as String).toList();
    } catch (e) {
      throw Exception('獲取封鎖名單失敗: $e');
    }
  }

  /// 獲取封鎖我的用戶 ID 列表 (被動封鎖)
  ///
  /// [userId] 用戶 ID
  Future<List<String>> getBlockedByIds(String userId) async {
    try {
      final query = await _blocksCollection
          .where('blockedId', isEqualTo: userId)
          .get();

      return query.docs.map((doc) => doc['blockerId'] as String).toList();
    } catch (e) {
      throw Exception('獲取被封鎖名單失敗: $e');
    }
  }

  /// 監聽被我封鎖的用戶 ID 列表
  ///
  /// [userId] 用戶 ID
  Stream<List<String>> getBlockedUserIdsStream(String userId) {
    return _blocksCollection
        .where('blockerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc['blockedId'] as String).toList();
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// 用戶封鎖服務 - 處理用戶封鎖與解除封鎖邏輯
///
/// 負責管理 `user_blocks` 集合，並提供查詢黑名單的功能
class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 封鎖記錄集合引用
  CollectionReference get _blocksCollection => _firestore.collection('user_blocks');

  /// 封鎖用戶
  ///
  /// [blockerId] 發起封鎖的用戶 ID
  /// [blockedId] 被封鎖的用戶 ID
  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      // 檢查是否已經封鎖，避免重複記錄
      final existingBlock = await _blocksCollection
          .where('blockerId', isEqualTo: blockerId)
          .where('blockedId', isEqualTo: blockedId)
          .limit(1)
          .get();

      if (existingBlock.docs.isNotEmpty) {
        return; // 已經封鎖過
      }

      await _blocksCollection.add({
        'blockerId': blockerId,
        'blockedId': blockedId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖用戶
  ///
  /// [blockerId] 發起封鎖的用戶 ID (當前用戶)
  /// [blockedId] 被封鎖的用戶 ID
  Future<void> unblockUser(String blockerId, String blockedId) async {
    try {
      final query = await _blocksCollection
          .where('blockerId', isEqualTo: blockerId)
          .where('blockedId', isEqualTo: blockedId)
          .get();

      final batch = _firestore.batch();
      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 獲取與該用戶相關的所有封鎖 ID 列表 (互相不可見)
  ///
  /// 包含:
  /// 1. 該用戶封鎖的人
  /// 2. 封鎖該用戶的人
  ///
  /// [userId] 當前用戶 ID
  /// 返回所有需要隱藏的用戶 ID 列表
  Future<List<String>> getBlockedUserIds(String userId) async {
    try {
      final blockedIds = <String>{};

      // 1. 我封鎖的人
      final myBlocks = await _blocksCollection
          .where('blockerId', isEqualTo: userId)
          .get();

      for (var doc in myBlocks.docs) {
        blockedIds.add(doc['blockedId'] as String);
      }

      // 2. 封鎖我的人
      final blockedMe = await _blocksCollection
          .where('blockedId', isEqualTo: userId)
          .get();

      for (var doc in blockedMe.docs) {
        blockedIds.add(doc['blockerId'] as String);
      }

      return blockedIds.toList();
    } catch (e) {
      throw Exception('獲取封鎖名單失敗: $e');
    }
  }

  /// 檢查是否已封鎖特定用戶
  ///
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 目標用戶 ID
  Future<bool> isUserBlocked(String currentUserId, String targetUserId) async {
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
}

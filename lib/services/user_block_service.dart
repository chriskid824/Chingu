import 'package:cloud_firestore/cloud_firestore.dart';

/// 用戶封鎖服務 - 管理用戶之間的封鎖關係
class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _blocksCollection => _firestore.collection('user_blocks');

  /// 封鎖用戶
  ///
  /// [blockerId] 發起封鎖的用戶 ID
  /// [blockedId] 被封鎖的用戶 ID
  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
        // 檢查是否已存在封鎖關係，避免重複
        final query = await _blocksCollection
            .where('blockerId', isEqualTo: blockerId)
            .where('blockedId', isEqualTo: blockedId)
            .get();

        if (query.docs.isEmpty) {
             await _blocksCollection.add({
                'blockerId': blockerId,
                'blockedId': blockedId,
                'timestamp': FieldValue.serverTimestamp(),
            });
        }
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖用戶
  ///
  /// [blockerId] 發起解除封鎖的用戶 ID
  /// [blockedId] 被解封的用戶 ID
  Future<void> unblockUser(String blockerId, String blockedId) async {
    try {
      final query = await _blocksCollection
          .where('blockerId', isEqualTo: blockerId)
          .where('blockedId', isEqualTo: blockedId)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('解除封鎖用戶失敗: $e');
    }
  }

  /// 獲取所有相關的封鎖 ID（包括封鎖我的和我封鎖的）
  /// 這些用戶不應出現在配對或搜尋結果中
  ///
  /// [userId] 當前用戶 ID
  /// 返回相關的用戶 ID 列表
  Future<List<String>> getBlockedUserIds(String userId) async {
    try {
      // 查詢我封鎖的人
      final blockedByMe = await _blocksCollection
          .where('blockerId', isEqualTo: userId)
          .get();

      // 查詢封鎖我的人
      final blockedMe = await _blocksCollection
          .where('blockedId', isEqualTo: userId)
          .get();

      final Set<String> ids = {};

      for (var doc in blockedByMe.docs) {
        ids.add(doc['blockedId'] as String);
      }

      for (var doc in blockedMe.docs) {
        ids.add(doc['blockerId'] as String);
      }

      return ids.toList();
    } catch (e) {
      throw Exception('獲取封鎖名單失敗: $e');
    }
  }

  /// 檢查是否被封鎖或封鎖對方
  ///
  /// [userId1] 用戶 1 ID
  /// [userId2] 用戶 2 ID
  /// 返回 true 如果任一方封鎖了另一方
  Future<bool> isBlocked(String userId1, String userId2) async {
    try {
      // Check if userId1 blocked userId2
      final block1 = await _blocksCollection
          .where('blockerId', isEqualTo: userId1)
          .where('blockedId', isEqualTo: userId2)
          .limit(1)
          .get();

      if (block1.docs.isNotEmpty) return true;

      // Check if userId2 blocked userId1
      final block2 = await _blocksCollection
          .where('blockerId', isEqualTo: userId2)
          .where('blockedId', isEqualTo: userId1)
          .limit(1)
          .get();

      return block2.docs.isNotEmpty;
    } catch (e) {
      throw Exception('檢查封鎖狀態失敗: $e');
    }
  }
}

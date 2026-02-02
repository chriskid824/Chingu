import 'package:cloud_firestore/cloud_firestore.dart';

/// 用戶封鎖服務 - 處理用戶封鎖與解除封鎖邏輯
class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _blocksCollection => _firestore.collection('user_blocks');

  /// 封鎖用戶
  ///
  /// [currentUserId] 執行封鎖的用戶 ID
  /// [targetUserId] 被封鎖的用戶 ID
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      // 檢查是否已經封鎖
      final existingBlock = await _blocksCollection
          .where('blockerId', isEqualTo: currentUserId)
          .where('blockedId', isEqualTo: targetUserId)
          .get();

      if (existingBlock.docs.isNotEmpty) {
        return; // 已經封鎖
      }

      await _blocksCollection.add({
        'blockerId': currentUserId,
        'blockedId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('用戶 $currentUserId 已封鎖 $targetUserId');
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

      print('用戶 $currentUserId 已解除封鎖 $targetUserId');
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 獲取該用戶主動封鎖的用戶 ID 列表
  ///
  /// [currentUserId] 當前用戶 ID
  Future<List<String>> getBlockedUserIds(String currentUserId) async {
    try {
      final query = await _blocksCollection
          .where('blockerId', isEqualTo: currentUserId)
          .get();

      return query.docs.map((doc) => doc['blockedId'] as String).toList();
    } catch (e) {
      throw Exception('獲取封鎖名單失敗: $e');
    }
  }

  /// 獲取封鎖該用戶的用戶 ID 列表
  ///
  /// [currentUserId] 當前用戶 ID
  Future<List<String>> getUsersWhoBlocked(String currentUserId) async {
    try {
      final query = await _blocksCollection
          .where('blockedId', isEqualTo: currentUserId)
          .get();

      return query.docs.map((doc) => doc['blockerId'] as String).toList();
    } catch (e) {
      throw Exception('獲取被封鎖名單失敗: $e');
    }
  }

  /// 獲取所有應排除的用戶 ID（我封鎖的 + 封鎖我的）
  ///
  /// [currentUserId] 當前用戶 ID
  Future<List<String>> getAllExcludedUserIds(String currentUserId) async {
    try {
      final blockedByMe = await getBlockedUserIds(currentUserId);
      final blockedMe = await getUsersWhoBlocked(currentUserId);

      // 合併並去重
      final allIds = {...blockedByMe, ...blockedMe}.toList();
      return allIds;
    } catch (e) {
      throw Exception('獲取排除名單失敗: $e');
    }
  }

  /// 檢查特定用戶是否被封鎖
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

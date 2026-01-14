import 'package:cloud_firestore/cloud_firestore.dart';

class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _blocksCollection =>
      _firestore.collection('user_blocks');

  /// 封鎖用戶
  ///
  /// [blockerId] 發起封鎖的用戶 ID
  /// [blockedId] 被封鎖的用戶 ID
  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      // 使用複合 ID 確保唯一性並節省查詢成本
      await _blocksCollection.doc('${blockerId}_${blockedId}').set({
        'blockerId': blockerId,
        'blockedId': blockedId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖
  ///
  /// [blockerId] 發起解除封鎖的用戶 ID
  /// [blockedId] 被解除封鎖的用戶 ID
  Future<void> unblockUser(String blockerId, String blockedId) async {
    try {
      await _blocksCollection.doc('${blockerId}_${blockedId}').delete();
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 檢查是否已封鎖
  ///
  /// [blockerId] 發起封鎖的用戶 ID
  /// [blockedId] 被封鎖的用戶 ID
  Future<bool> isBlocked(String blockerId, String blockedId) async {
    try {
      final doc = await _blocksCollection.doc('${blockerId}_${blockedId}').get();
      return doc.exists;
    } catch (e) {
      throw Exception('檢查封鎖狀態失敗: $e');
    }
  }

  /// 獲取該用戶封鎖的所有用戶 ID
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

  /// 獲取封鎖該用戶的所有用戶 ID
  ///
  /// [userId] 用戶 ID
  Future<List<String>> getBlockedByList(String userId) async {
    try {
      final query = await _blocksCollection
          .where('blockedId', isEqualTo: userId)
          .get();

      return query.docs.map((doc) => doc['blockerId'] as String).toList();
    } catch (e) {
      throw Exception('獲取被封鎖名單失敗: $e');
    }
  }

  /// 獲取需要排除的用戶 ID 列表 (我封鎖的 + 封鎖我的)
  ///
  /// [userId] 當前用戶 ID
  Future<List<String>> getExcludedUserIds(String userId) async {
    try {
      final blocked = await getBlockedUserIds(userId);
      final blockedBy = await getBlockedByList(userId);

      // 合併並去重
      final Set<String> excluded = {};
      excluded.addAll(blocked);
      excluded.addAll(blockedBy);

      return excluded.toList();
    } catch (e) {
      throw Exception('獲取排除名單失敗: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// 用戶封鎖服務 - 處理用戶封鎖邏輯
class UserBlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 封鎖集合引用
  CollectionReference get _blocksCollection => _firestore.collection('user_blocks');

  /// 封鎖用戶
  ///
  /// [blockerId] 發起封鎖的用戶 ID
  /// [blockedId] 被封鎖的用戶 ID
  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      final docId = '${blockerId}_$blockedId';
      await _blocksCollection.doc(docId).set({
        'blockerId': blockerId,
        'blockedId': blockedId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖
  ///
  /// [blockerId] 發起封鎖的用戶 ID
  /// [blockedId] 被封鎖的用戶 ID
  Future<void> unblockUser(String blockerId, String blockedId) async {
    try {
      final docId = '${blockerId}_$blockedId';
      await _blocksCollection.doc(docId).delete();
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
      final docId = '${blockerId}_$blockedId';
      final doc = await _blocksCollection.doc(docId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// 獲取我封鎖的用戶 ID 列表
  ///
  /// [userId] 當前用戶 ID
  Future<List<String>> getBlockedUserIds(String userId) async {
    try {
      final query = await _blocksCollection
          .where('blockerId', isEqualTo: userId)
          .get();

      return query.docs.map((doc) => doc['blockedId'] as String).toList();
    } catch (e) {
      print('獲取封鎖列表失敗: $e');
      return [];
    }
  }

  /// 獲取封鎖我的用戶 ID 列表
  ///
  /// [userId] 當前用戶 ID
  Future<List<String>> getBlockedByUserIds(String userId) async {
    try {
      final query = await _blocksCollection
          .where('blockedId', isEqualTo: userId)
          .get();

      return query.docs.map((doc) => doc['blockerId'] as String).toList();
    } catch (e) {
      print('獲取被封鎖列表失敗: $e');
      return [];
    }
  }
}

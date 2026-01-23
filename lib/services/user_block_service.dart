import 'package:cloud_firestore/cloud_firestore.dart';

/// 用戶封鎖服務 - 處理用戶封鎖邏輯
class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _blocksCollection => _firestore.collection('user_blocks');

  /// 封鎖用戶
  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      if (blockerId == blockedId) return;

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
  Future<void> unblockUser(String blockerId, String blockedId) async {
    try {
      final docId = '${blockerId}_$blockedId';
      await _blocksCollection.doc(docId).delete();
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 獲取所有需要過濾的用戶 ID (我封鎖的 + 封鎖我的)
  Future<List<String>> getBlockedIds(String userId) async {
    try {
      // 1. 我封鎖的用戶
      final myBlocksQuery = await _blocksCollection
          .where('blockerId', isEqualTo: userId)
          .get();

      // 2. 封鎖我的用戶
      final blockedByQuery = await _blocksCollection
          .where('blockedId', isEqualTo: userId)
          .get();

      final Set<String> blockedIds = {};

      for (var doc in myBlocksQuery.docs) {
        blockedIds.add(doc['blockedId'] as String);
      }

      for (var doc in blockedByQuery.docs) {
        blockedIds.add(doc['blockerId'] as String);
      }

      return blockedIds.toList();
    } catch (e) {
      print('獲取封鎖名單失敗: $e');
      return [];
    }
  }

  /// 檢查兩用戶之間是否有封鎖關係
  Future<bool> isBlocked(String user1, String user2) async {
    try {
      final doc1 = await _blocksCollection.doc('${user1}_$user2').get();
      if (doc1.exists) return true;

      final doc2 = await _blocksCollection.doc('${user2}_$user1').get();
      if (doc2.exists) return true;

      return false;
    } catch (e) {
      return false;
    }
  }
}

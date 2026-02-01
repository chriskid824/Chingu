import 'package:cloud_firestore/cloud_firestore.dart';

class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _blocksCollection => _firestore.collection('user_blocks');

  /// 封鎖用戶
  Future<void> blockUser(String blockerId, String blockedId) async {
    final docId = '${blockerId}_${blockedId}';
    await _blocksCollection.doc(docId).set({
      'blockerId': blockerId,
      'blockedId': blockedId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// 解除封鎖
  Future<void> unblockUser(String blockerId, String blockedId) async {
    final docId = '${blockerId}_${blockedId}';
    await _blocksCollection.doc(docId).delete();
  }

  /// 檢查是否已封鎖
  Future<bool> isBlocked(String blockerId, String blockedId) async {
    final docId = '${blockerId}_${blockedId}';
    final doc = await _blocksCollection.doc(docId).get();
    return doc.exists;
  }

  /// 獲取我封鎖的用戶 ID 列表
  Future<List<String>> getBlockedUserIds(String userId) async {
    final query = await _blocksCollection
        .where('blockerId', isEqualTo: userId)
        .get();

    return query.docs
        .map((doc) => doc['blockedId'] as String)
        .toList();
  }

  /// 獲取封鎖我的用戶 ID 列表
  Future<List<String>> getIdsThatBlockedUser(String userId) async {
    final query = await _blocksCollection
        .where('blockedId', isEqualTo: userId)
        .get();

    return query.docs
        .map((doc) => doc['blockerId'] as String)
        .toList();
  }

  /// 獲取所有需要排除的用戶 ID (雙向封鎖)
  Future<List<String>> getAllExcludedUserIds(String userId) async {
    final blockedByMe = await getBlockedUserIds(userId);
    final blockedMe = await getIdsThatBlockedUser(userId);

    return {...blockedByMe, ...blockedMe}.toList();
  }
}

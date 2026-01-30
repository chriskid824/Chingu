import 'package:cloud_firestore/cloud_firestore.dart';

class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 獲取封鎖名單集合引用
  CollectionReference _blockedUsersCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('blocked_users');
  }

  /// 封鎖用戶
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      await _blockedUsersCollection(currentUserId).doc(targetUserId).set({
        'blockedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖用戶
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _blockedUsersCollection(currentUserId).doc(targetUserId).delete();
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 檢查是否已封鎖某用戶
  Future<bool> isBlocked(String currentUserId, String targetUserId) async {
    try {
      final doc = await _blockedUsersCollection(currentUserId).doc(targetUserId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('檢查封鎖狀態失敗: $e');
    }
  }

  /// 獲取所有已封鎖的用戶 ID
  Future<List<String>> getBlockedUserIds(String currentUserId) async {
    try {
      final snapshot = await _blockedUsersCollection(currentUserId).get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('獲取封鎖名單失敗: $e');
    }
  }
}

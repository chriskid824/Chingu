import 'package:cloud_firestore/cloud_firestore.dart';

/// 用戶封鎖服務 - 處理用戶封鎖邏輯
class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  /// 封鎖用戶
  ///
  /// [currentUserId] 當前操作用戶 ID
  /// [targetUserId] 要封鎖的目標用戶 ID
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      if (currentUserId == targetUserId) {
        throw Exception('無法封鎖自己');
      }

      await _usersCollection.doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([targetUserId]),
      });

      print('用戶 $currentUserId 成功封鎖 $targetUserId');
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖
  ///
  /// [currentUserId] 當前操作用戶 ID
  /// [targetUserId] 要解除封鎖的目標用戶 ID
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _usersCollection.doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([targetUserId]),
      });

      print('用戶 $currentUserId 成功解除封鎖 $targetUserId');
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 獲取被封鎖的用戶 ID 列表
  ///
  /// [currentUserId] 當前用戶 ID
  Future<List<String>> getBlockedUsers(String currentUserId) async {
    try {
      final doc = await _usersCollection.doc(currentUserId).get();
      if (!doc.exists) return [];

      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('blockedUsers')) {
        return List<String>.from(data['blockedUsers']);
      }
      return [];
    } catch (e) {
      throw Exception('獲取封鎖列表失敗: $e');
    }
  }
}

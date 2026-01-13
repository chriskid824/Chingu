import 'package:cloud_firestore/cloud_firestore.dart';

/// 用戶封鎖服務
class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  /// 封鎖用戶
  ///
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 要封鎖的目標用戶 ID
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) {
      throw Exception('無法封鎖自己');
    }

    try {
      await _usersCollection.doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([targetUserId])
      });

      // 可選：也可以同時將對方從配對列表移除，或在配對時過濾
      // 這裡僅處理資料層面的封鎖標記

      print('用戶 $currentUserId 已封鎖 $targetUserId');
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖
  ///
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 要解除封鎖的目標用戶 ID
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _usersCollection.doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([targetUserId])
      });

      print('用戶 $currentUserId 已解除封鎖 $targetUserId');
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 檢查是否已封鎖
  ///
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 目標用戶 ID
  Future<bool> isBlocked(String currentUserId, String targetUserId) async {
    try {
      final doc = await _usersCollection.doc(currentUserId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final blockedUsers = List<String>.from(data['blockedUsers'] ?? []);

      return blockedUsers.contains(targetUserId);
    } catch (e) {
      throw Exception('檢查封鎖狀態失敗: $e');
    }
  }
}

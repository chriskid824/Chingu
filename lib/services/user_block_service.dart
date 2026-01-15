import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';

/// 用戶封鎖服務 - 處理用戶封鎖相關邏輯
class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // 集合引用
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// 封鎖用戶
  ///
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 要封鎖的目標用戶 ID
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      if (currentUserId == targetUserId) {
        throw Exception('不能封鎖自己');
      }

      // 使用 arrayUnion 確保不重複添加
      await _usersCollection.doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([targetUserId])
      });

      print('用戶 $currentUserId 已封鎖 $targetUserId');
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖用戶
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
      throw Exception('解除封鎖用戶失敗: $e');
    }
  }

  /// 檢查是否已封鎖
  ///
  /// [currentUser] 當前用戶模型
  /// [targetUserId] 目標用戶 ID
  bool isBlocked(UserModel currentUser, String targetUserId) {
    return currentUser.blockedUsers.contains(targetUserId);
  }

  /// 檢查是否被封鎖 (需要獲取目標用戶資料，較耗時)
  ///
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 目標用戶 ID
  Future<bool> isBlockedBy(String currentUserId, String targetUserId) async {
    try {
      final doc = await _usersCollection.doc(targetUserId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final blockedUsers = List<String>.from(data['blockedUsers'] ?? []);

      return blockedUsers.contains(currentUserId);
    } catch (e) {
      print('檢查被封鎖狀態失敗: $e');
      return false;
    }
  }
}

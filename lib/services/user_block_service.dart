import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';

/// 用戶封鎖服務 - 處理封鎖與解除封鎖邏輯
class UserBlockService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;

  UserBlockService({
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  /// 封鎖用戶
  ///
  /// [currentUserId] 當前操作用戶 ID
  /// [targetUserId] 目標用戶 ID
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      if (currentUserId == targetUserId) {
        throw Exception('無法封鎖自己');
      }

      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([targetUserId]),
      });
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖用戶
  ///
  /// [currentUserId] 當前操作用戶 ID
  /// [targetUserId] 目標用戶 ID
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([targetUserId]),
      });
    } catch (e) {
      throw Exception('解除封鎖用戶失敗: $e');
    }
  }

  /// 獲取封鎖名單 ID 列表
  ///
  /// [currentUserId] 當前用戶 ID
  Future<List<String>> getBlockedUsers(String currentUserId) async {
    try {
      final user = await _firestoreService.getUser(currentUserId);
      return user?.blockedUsers ?? [];
    } catch (e) {
      throw Exception('獲取封鎖名單失敗: $e');
    }
  }

  /// 獲取詳細的封鎖用戶列表 (UserModel 列表)
  ///
  /// [currentUserId] 當前用戶 ID
  Future<List<UserModel>> getBlockedUsersDetails(String currentUserId) async {
    try {
      final blockedIds = await getBlockedUsers(currentUserId);
      if (blockedIds.isEmpty) return [];

      // 批次獲取用戶資料
      return await _firestoreService.getBatchUsers(blockedIds);
    } catch (e) {
      throw Exception('獲取詳細封鎖名單失敗: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/firestore_service.dart';

/// 用戶封鎖服務
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
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 要封鎖的目標用戶 ID
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      if (currentUserId == targetUserId) {
        throw Exception('不能封鎖自己');
      }

      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([targetUserId]),
      });

      print('已成功封鎖用戶: $targetUserId');
    } catch (e) {
      print('封鎖用戶失敗: $e');
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖用戶
  ///
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 要解除封鎖的目標用戶 ID
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([targetUserId]),
      });

      print('已成功解除封鎖用戶: $targetUserId');
    } catch (e) {
      print('解除封鎖用戶失敗: $e');
      throw Exception('解除封鎖用戶失敗: $e');
    }
  }

  /// 獲取已封鎖的用戶 ID 列表
  ///
  /// [currentUserId] 當前用戶 ID
  Future<List<String>> getBlockedUserIds(String currentUserId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return [];

      final data = userDoc.data();
      if (data == null || !data.containsKey('blockedUsers')) return [];

      return List<String>.from(data['blockedUsers']);
    } catch (e) {
      print('獲取封鎖名單失敗: $e');
      return [];
    }
  }

  /// 檢查用戶是否被封鎖
  ///
  /// [currentUserId] 當前用戶 ID
  /// [targetUserId] 目標用戶 ID
  Future<bool> isUserBlocked(String currentUserId, String targetUserId) async {
    try {
      final blockedIds = await getBlockedUserIds(currentUserId);
      return blockedIds.contains(targetUserId);
    } catch (e) {
      print('檢查封鎖狀態失敗: $e');
      return false;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/firestore_service.dart';

class UserBlockService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;

  UserBlockService({
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  CollectionReference get _usersCollection => _firestore.collection('users');

  /// 封鎖用戶
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      if (currentUserId == targetUserId) {
        throw Exception('不能封鎖自己');
      }

      await _usersCollection.doc(currentUserId).update({
        'blockedUserIds': FieldValue.arrayUnion([targetUserId]),
      });

      print('用戶 $currentUserId 已封鎖 $targetUserId');
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _usersCollection.doc(currentUserId).update({
        'blockedUserIds': FieldValue.arrayRemove([targetUserId]),
      });
       print('用戶 $currentUserId 已解除封鎖 $targetUserId');
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 檢查是否已封鎖
  Future<bool> isBlocked(String currentUserId, String targetUserId) async {
    try {
      final user = await _firestoreService.getUser(currentUserId);
      if (user == null) return false;
      return user.blockedUserIds.contains(targetUserId);
    } catch (e) {
      print('檢查封鎖狀態失敗: $e');
      return false;
    }
  }

  /// 獲取已封鎖的用戶列表 (IDs)
  Future<List<String>> getBlockedUserIds(String currentUserId) async {
     try {
      final user = await _firestoreService.getUser(currentUserId);
      if (user == null) return [];
      return user.blockedUserIds;
    } catch (e) {
      throw Exception('獲取封鎖列表失敗: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// 用戶封鎖服務
class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 封鎖用戶
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([targetUserId])
      });
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([targetUserId])
      });
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }
}

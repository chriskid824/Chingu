import 'package:cloud_firestore/cloud_firestore.dart';

class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  /// 封鎖用戶
  Future<void> blockUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      await _usersCollection.doc(currentUserId).update({
        'blockedUserIds': FieldValue.arrayUnion([targetUserId]),
      });
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖用戶
  Future<void> unblockUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      await _usersCollection.doc(currentUserId).update({
        'blockedUserIds': FieldValue.arrayRemove([targetUserId]),
      });
    } catch (e) {
      throw Exception('解除封鎖用戶失敗: $e');
    }
  }

  /// 獲取封鎖名單
  Future<List<String>> getBlockedUsers(String currentUserId) async {
    try {
      final doc = await _usersCollection.doc(currentUserId).get();
      if (!doc.exists) return [];

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('blockedUserIds')) {
        return [];
      }

      return List<String>.from(data['blockedUserIds']);
    } catch (e) {
      throw Exception('獲取封鎖名單失敗: $e');
    }
  }
}

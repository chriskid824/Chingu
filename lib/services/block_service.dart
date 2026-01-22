import 'package:cloud_firestore/cloud_firestore.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _blocksCollection => _firestore.collection('blocks'); // or subcollection

  /// 封鎖用戶
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      await _usersCollection.doc(currentUserId).collection('blocked_users').doc(targetUserId).set({
        'blockedAt': FieldValue.serverTimestamp(),
      });
      // Optionally remove existing matches/chats?
      // For now just record the block.
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _usersCollection.doc(currentUserId).collection('blocked_users').doc(targetUserId).delete();
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 獲取封鎖名單
  Future<List<String>> getBlockedUsers(String currentUserId) async {
    try {
      final snapshot = await _usersCollection.doc(currentUserId).collection('blocked_users').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }
}

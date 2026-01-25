import 'package:cloud_firestore/cloud_firestore.dart';

class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _blocksCollection => _firestore.collection('user_blocks');

  /// Block a user
  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      final docId = '${blockerId}_$blockedId';
      await _blocksCollection.doc(docId).set({
        'blockerId': blockerId,
        'blockedId': blockedId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('User $blockerId blocked $blockedId');
    } catch (e) {
      print('Error blocking user: $e');
      throw Exception('Block user failed: $e');
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String blockerId, String blockedId) async {
    try {
      final docId = '${blockerId}_$blockedId';
      await _blocksCollection.doc(docId).delete();
      print('User $blockerId unblocked $blockedId');
    } catch (e) {
      print('Error unblocking user: $e');
      throw Exception('Unblock user failed: $e');
    }
  }

  /// Get list of user IDs blocked by [userId]
  Future<List<String>> getBlockedUserIds(String userId) async {
    try {
      final query = await _blocksCollection
          .where('blockerId', isEqualTo: userId)
          .get();
      return query.docs.map((doc) => doc['blockedId'] as String).toList();
    } catch (e) {
      print('Error fetching blocked users: $e');
      return [];
    }
  }

  /// Get list of user IDs who blocked [userId]
  Future<List<String>> getBlockedByUserIds(String userId) async {
    try {
      final query = await _blocksCollection
          .where('blockedId', isEqualTo: userId)
          .get();
      return query.docs.map((doc) => doc['blockerId'] as String).toList();
    } catch (e) {
      print('Error fetching users who blocked me: $e');
      return [];
    }
  }

  /// Check if a block exists (blocker -> blocked)
  Future<bool> isBlocked(String blockerId, String blockedId) async {
    try {
      final docId = '${blockerId}_$blockedId';
      final doc = await _blocksCollection.doc(docId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking block status: $e');
      return false;
    }
  }
}

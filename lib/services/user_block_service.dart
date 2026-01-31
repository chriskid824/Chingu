import 'package:cloud_firestore/cloud_firestore.dart';

class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Block a user
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(targetUserId)
          .set({
        'uid': targetUserId,
        'blockedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(targetUserId)
          .delete();
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  /// Get list of user IDs blocked by current user
  Future<List<String>> getBlockedUserIds(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Failed to get blocked users: $e');
    }
  }

  /// Get list of user IDs who have blocked the current user
  Future<List<String>> getBlockedByUserIds(String currentUserId) async {
    try {
      // Use collection group query to find who blocked currentUserId
      // Note: This requires an index in Firestore usually
      final snapshot = await _firestore
          .collectionGroup('blocked_users')
          .where('uid', isEqualTo: currentUserId)
          .get();

      // The parent of the blocked_users subcollection is the user who blocked me
      return snapshot.docs
          .map((doc) => doc.reference.parent.parent?.id)
          .where((id) => id != null)
          .cast<String>()
          .toList();
    } catch (e) {
      // If index is missing or other error, return empty list to not break flow
      print('Warning: Failed to get blocked-by users (check indexes): $e');
      return [];
    }
  }

  /// Check if a user is blocked by current user
  Future<bool> isBlocked(String currentUserId, String targetUserId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check block status: $e');
    }
  }
}

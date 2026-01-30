import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService {
  final FirebaseFirestore _firestore;

  FavoriteService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection reference: users/{userId}/favorites/{targetUserId}

  /// Toggle favorite status
  /// Returns true if added, false if removed
  Future<bool> toggleFavorite(String userId, String targetUserId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(targetUserId);

      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
        return false; // Removed
      } else {
        await docRef.set({
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true; // Added
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  /// Check if user is favorited
  Future<bool> isFavorite(String userId, String targetUserId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  /// Get stream of favorite user IDs
  Stream<List<String>> getFavoritesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
}

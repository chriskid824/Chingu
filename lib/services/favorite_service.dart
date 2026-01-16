import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _usersCollection() => _firestore.collection('users');

  /// Add a user to favorites
  Future<void> addFavorite(String currentUserId, String targetUserId) async {
    try {
      await _usersCollection()
          .doc(currentUserId)
          .collection('favorites')
          .doc(targetUserId)
          .set({
        'uid': targetUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  /// Remove a user from favorites
  Future<void> removeFavorite(String currentUserId, String targetUserId) async {
    try {
      await _usersCollection()
          .doc(currentUserId)
          .collection('favorites')
          .doc(targetUserId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  /// Check if a user is favorited
  Future<bool> isFavorite(String currentUserId, String targetUserId) async {
    try {
      final doc = await _usersCollection()
          .doc(currentUserId)
          .collection('favorites')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check favorite status: $e');
    }
  }

  /// Get list of favorite user IDs (Stream)
  Stream<List<String>> getFavoritesStream(String currentUserId) {
    return _usersCollection()
        .doc(currentUserId)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  /// Get list of favorite user IDs (Future)
  Future<List<String>> getFavorites(String currentUserId) async {
    try {
      final snapshot = await _usersCollection()
          .doc(currentUserId)
          .collection('favorites')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Failed to get favorites: $e');
    }
  }
}

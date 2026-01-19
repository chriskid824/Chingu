import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';

class FavoritesService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;

  FavoritesService({
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  /// Collection reference: users/{userId}/favorites
  CollectionReference _getFavoritesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  /// Add a user to favorites
  Future<void> addFavorite(String currentUserId, String targetUserId) async {
    try {
      await _getFavoritesCollection(currentUserId).doc(targetUserId).set({
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  /// Remove a user from favorites
  Future<void> removeFavorite(String currentUserId, String targetUserId) async {
    try {
      await _getFavoritesCollection(currentUserId).doc(targetUserId).delete();
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  /// Check if a user is a favorite
  Future<bool> isFavorite(String currentUserId, String targetUserId) async {
    try {
      final doc = await _getFavoritesCollection(currentUserId).doc(targetUserId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check favorite status: $e');
    }
  }

  /// Get all favorite users
  Future<List<UserModel>> getFavorites(String currentUserId) async {
    try {
      final snapshot = await _getFavoritesCollection(currentUserId)
          .orderBy('addedAt', descending: true)
          .get();

      final favoriteUserIds = snapshot.docs.map((doc) => doc.id).toList();

      if (favoriteUserIds.isEmpty) {
        return [];
      }

      return await _firestoreService.getBatchUsers(favoriteUserIds);
    } catch (e) {
      throw Exception('Failed to get favorites: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';

class FavoriteService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;

  FavoriteService({
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  CollectionReference _favoritesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  Future<void> addFavorite(String userId, String targetUserId) async {
    try {
      await _favoritesCollection(userId).doc(targetUserId).set({
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  Future<void> removeFavorite(String userId, String targetUserId) async {
    try {
      await _favoritesCollection(userId).doc(targetUserId).delete();
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  Future<bool> isFavorite(String userId, String targetUserId) async {
    try {
      final doc = await _favoritesCollection(userId).doc(targetUserId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<List<UserModel>> getFavorites(String userId) async {
    try {
      final snapshot = await _favoritesCollection(userId).orderBy('createdAt', descending: true).get();

      if (snapshot.docs.isEmpty) return [];

      final userIds = snapshot.docs.map((doc) => doc.id).toList();

      return await _firestoreService.getBatchUsers(userIds);
    } catch (e) {
      throw Exception('Failed to get favorites: $e');
    }
  }
}

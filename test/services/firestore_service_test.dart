import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService firestoreService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
  });

  group('FirestoreService Favorites', () {
    const userId = 'user_1';
    const targetUserId1 = 'target_1';
    const targetUserId2 = 'target_2';

    test('addFavorite adds a favorite', () async {
      await firestoreService.addFavorite(userId, targetUserId1);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(targetUserId1)
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()!.containsKey('addedAt'), isTrue);
    });

    test('isFavorite returns true for existing favorite', () async {
      await firestoreService.addFavorite(userId, targetUserId1);

      final isFav = await firestoreService.isFavorite(userId, targetUserId1);
      expect(isFav, isTrue);
    });

    test('isFavorite returns false for non-existing favorite', () async {
      final isFav = await firestoreService.isFavorite(userId, targetUserId1);
      expect(isFav, isFalse);
    });

    test('removeFavorite removes a favorite', () async {
      await firestoreService.addFavorite(userId, targetUserId1);

      var isFav = await firestoreService.isFavorite(userId, targetUserId1);
      expect(isFav, isTrue);

      await firestoreService.removeFavorite(userId, targetUserId1);

      isFav = await firestoreService.isFavorite(userId, targetUserId1);
      expect(isFav, isFalse);
    });

    test('getFavorites returns favorites', () async {
      await firestoreService.addFavorite(userId, targetUserId1);
      await firestoreService.addFavorite(userId, targetUserId2);

      final favorites = await firestoreService.getFavorites(userId);

      expect(favorites.length, 2);
      expect(favorites, contains(targetUserId1));
      expect(favorites, contains(targetUserId2));
    });

    test('getBatchUsers returns users for given IDs', () async {
      // Setup: Add some users
      await fakeFirestore.collection('users').doc('user1').set({
        'name': 'User 1',
        'email': 'user1@example.com',
        'age': 25,
        'gender': 'male',
        'job': 'Developer',
        'interests': [],
        'country': 'Taiwan',
        'city': 'Taipei',
        'district': 'Xinyi',
        'preferredMatchType': 'any',
        'minAge': 18,
        'maxAge': 30,
        'budgetRange': 1,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
      });

      await fakeFirestore.collection('users').doc('user2').set({
        'name': 'User 2',
        'email': 'user2@example.com',
        'age': 26,
        'gender': 'female',
        'job': 'Designer',
        'interests': [],
        'country': 'Taiwan',
        'city': 'Taipei',
        'district': 'Da-an',
        'preferredMatchType': 'any',
        'minAge': 18,
        'maxAge': 30,
        'budgetRange': 1,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
      });

      final users = await firestoreService.getBatchUsers(['user1', 'user2']);

      expect(users.length, 2);
      expect(users.any((u) => u.uid == 'user1'), isTrue);
      expect(users.any((u) => u.uid == 'user2'), isTrue);
      expect(users.firstWhere((u) => u.uid == 'user1').name, 'User 1');
    });
  });
}

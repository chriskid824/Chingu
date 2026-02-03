import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/favorite_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class FakeFirestoreService extends Fake implements FirestoreService {
  @override
  Future<List<UserModel>> getBatchUsers(List<String> uids) async {
    return uids.map((uid) => UserModel(
      uid: uid,
      name: 'User $uid',
      email: '$uid@test.com',
      age: 25,
      gender: 'male',
      job: 'Dev',
      interests: [],
      country: 'TW',
      city: 'Taipei',
      district: 'Xinyi',
      preferredMatchType: 'any',
      minAge: 18,
      maxAge: 30,
      budgetRange: 1,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    )).toList();
  }
}

void main() {
  late FavoriteService favoriteService;
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirestoreService fakeFirestoreService;

  const String userId = 'user1';
  const String targetUserId = 'target1';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeFirestoreService = FakeFirestoreService();
    favoriteService = FavoriteService(
      firestore: fakeFirestore,
      firestoreService: fakeFirestoreService,
    );
  });

  group('FavoriteService', () {
    test('addFavorite should add document to favorites collection', () async {
      await favoriteService.addFavorite(userId, targetUserId);

      final doc = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(targetUserId)
          .get();

      expect(doc.exists, true);
      expect(doc.data()!.containsKey('createdAt'), true);
    });

    test('removeFavorite should remove document from favorites collection', () async {
      // Arrange
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(targetUserId)
          .set({'createdAt': DateTime.now()});

      // Act
      await favoriteService.removeFavorite(userId, targetUserId);

      // Assert
      final doc = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(targetUserId)
          .get();

      expect(doc.exists, false);
    });

    test('isFavorite should return true if document exists', () async {
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(targetUserId)
          .set({'createdAt': DateTime.now()});

      final result = await favoriteService.isFavorite(userId, targetUserId);
      expect(result, true);
    });

    test('isFavorite should return false if document does not exist', () async {
      final result = await favoriteService.isFavorite(userId, targetUserId);
      expect(result, false);
    });

    test('getFavorites should return list of UserModels', () async {
      // Arrange
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc('userA')
          .set({'createdAt': DateTime.now()});

      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc('userB')
          .set({'createdAt': DateTime.now()});

      // Act
      final results = await favoriteService.getFavorites(userId);

      // Assert
      expect(results.length, 2);
      expect(results.any((u) => u.uid == 'userA'), true);
      expect(results.any((u) => u.uid == 'userB'), true);
    });
  });
}

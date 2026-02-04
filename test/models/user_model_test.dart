import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel Favorites', () {
    final baseUserMap = {
      'name': 'Test User',
      'email': 'test@example.com',
      'age': 25,
      'gender': 'male',
      'job': 'Developer',
      'interests': ['coding'],
      'country': 'Taiwan',
      'city': 'Taipei',
      'district': 'Xinyi',
      'preferredMatchType': 'any',
      'minAge': 20,
      'maxAge': 30,
      'budgetRange': 1,
      'isActive': true,
      'createdAt': Timestamp.now(),
      'lastLogin': Timestamp.now(),
      'subscription': 'free',
      'totalDinners': 0,
      'totalMatches': 0,
      'averageRating': 0.0,
      'isTwoFactorEnabled': false,
      'twoFactorMethod': 'email',
    };

    test('should parse favorites from map', () {
      final map = Map<String, dynamic>.from(baseUserMap);
      map['favorites'] = ['user1', 'user2'];

      final user = UserModel.fromMap(map, 'test_uid');

      expect(user.favorites, containsAll(['user1', 'user2']));
      expect(user.favorites.length, 2);
    });

    test('should default favorites to empty list', () {
      final map = Map<String, dynamic>.from(baseUserMap);
      // No favorites key

      final user = UserModel.fromMap(map, 'test_uid');

      expect(user.favorites, isEmpty);
    });

    test('should serialize favorites to map', () {
      final user = UserModel(
        uid: 'test_uid',
        name: 'Test',
        email: 'test@test.com',
        age: 20,
        gender: 'male',
        job: 'dev',
        interests: [],
        country: 'TW',
        city: 'TP',
        district: 'XY',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        favorites: ['fav1'],
      );

      final map = user.toMap();
      expect(map['favorites'], ['fav1']);
    });

    test('copyWith should update favorites', () {
      final user = UserModel(
        uid: 'test_uid',
        name: 'Test',
        email: 'test@test.com',
        age: 20,
        gender: 'male',
        job: 'dev',
        interests: [],
        country: 'TW',
        city: 'TP',
        district: 'XY',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        favorites: ['fav1'],
      );

      final updatedUser = user.copyWith(favorites: ['fav1', 'fav2']);
      expect(updatedUser.favorites, ['fav1', 'fav2']);

      final sameUser = user.copyWith(name: 'New Name');
      expect(sameUser.favorites, ['fav1']);
    });
  });
}

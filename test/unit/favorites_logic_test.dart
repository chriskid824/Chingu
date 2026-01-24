import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock Timestamp for testing since we are not running in a flutter environment with firebase
class MockTimestamp extends Timestamp {
  MockTimestamp(super.seconds, super.nanoseconds);
}

void main() {
  group('UserModel Favorites Logic', () {
    final now = DateTime.now();
    final timestamp = Timestamp.fromDate(now);

    final baseMap = {
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
      'createdAt': timestamp,
      'lastLogin': timestamp,
      'subscription': 'free',
      'totalDinners': 0,
      'totalMatches': 0,
      'averageRating': 5.0,
      'isTwoFactorEnabled': false,
      'twoFactorMethod': 'email',
    };

    test('should parse favoriteUserIds from map', () {
      final map = Map<String, dynamic>.from(baseMap);
      map['favoriteUserIds'] = ['user1', 'user2'];

      final user = UserModel.fromMap(map, 'test_uid');

      expect(user.favoriteUserIds, containsAll(['user1', 'user2']));
      expect(user.favoriteUserIds.length, 2);
    });

    test('should handle missing favoriteUserIds in map', () {
      final map = Map<String, dynamic>.from(baseMap);
      // favoriteUserIds missing

      final user = UserModel.fromMap(map, 'test_uid');

      expect(user.favoriteUserIds, isEmpty);
    });

    test('should serialize favoriteUserIds to map', () {
      final user = UserModel(
        uid: 'test_uid',
        name: 'Test',
        email: 'test@example.com',
        age: 20,
        gender: 'female',
        job: 'dev',
        interests: [],
        country: 'TW',
        city: 'TP',
        district: 'XY',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: now,
        lastLogin: now,
        favoriteUserIds: ['fav1', 'fav2'],
      );

      final map = user.toMap();

      expect(map['favoriteUserIds'], containsAll(['fav1', 'fav2']));
    });

    test('copyWith should update favoriteUserIds', () {
      final user = UserModel(
        uid: 'test_uid',
        name: 'Test',
        email: 'test@example.com',
        age: 20,
        gender: 'female',
        job: 'dev',
        interests: [],
        country: 'TW',
        city: 'TP',
        district: 'XY',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: now,
        lastLogin: now,
        favoriteUserIds: ['fav1'],
      );

      final updated = user.copyWith(favoriteUserIds: ['fav1', 'fav2']);

      expect(updated.favoriteUserIds, containsAll(['fav1', 'fav2']));
      expect(updated.favoriteUserIds.length, 2);
      expect(user.favoriteUserIds.length, 1); // Original unchanged
    });
  });
}

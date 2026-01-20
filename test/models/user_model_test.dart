import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    test('should correctly serialize and deserialize favorites', () {
      final user = UserModel(
        uid: 'user1',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Developer',
        interests: ['coding'],
        country: 'Taiwan',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        favorites: ['user2', 'user3'],
      );

      final map = user.toMap();
      expect(map['favorites'], ['user2', 'user3']);

      final newUser = UserModel.fromMap(map, 'user1');
      expect(newUser.favorites, ['user2', 'user3']);
    });

    test('should default favorites to empty list', () {
      final map = {
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
        'minAge': 18,
        'maxAge': 30,
        'budgetRange': 1,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
      };

      final user = UserModel.fromMap(map, 'user1');
      expect(user.favorites, isEmpty);
    });

    test('copyWith should update favorites', () {
      final user = UserModel(
        uid: 'user1',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Developer',
        interests: ['coding'],
        country: 'Taiwan',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      final updatedUser = user.copyWith(favorites: ['newFav']);
      expect(updatedUser.favorites, ['newFav']);
      expect(updatedUser.name, 'Test User');
    });
  });
}

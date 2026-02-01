import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    test('should support favoriteIds', () {
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Dev',
        interests: ['Code'],
        country: 'TW',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        favoriteIds: ['user2', 'user3'],
      );

      expect(user.favoriteIds, contains('user2'));
      expect(user.favoriteIds, contains('user3'));
      expect(user.favoriteIds.length, 2);

      final map = user.toMap();
      expect(map['favoriteIds'], contains('user2'));

      final newUser = UserModel.fromMap(map, '123');
      expect(newUser.favoriteIds, contains('user2'));
    });

    test('copyWith should update favoriteIds', () {
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Dev',
        interests: ['Code'],
        country: 'TW',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        favoriteIds: ['user2'],
      );

      final updated = user.copyWith(favoriteIds: ['user3']);
      expect(updated.favoriteIds, ['user3']);
      expect(user.favoriteIds, ['user2']); // Original unchanged
    });
  });
}

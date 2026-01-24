import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel', () {
    test('should correctly parse totalMessagesSent from map', () {
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
        'minAge': 20,
        'maxAge': 30,
        'budgetRange': 1,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        'subscription': 'free',
        'totalDinners': 5,
        'totalMatches': 10,
        'totalMessagesSent': 42,
        'averageRating': 4.5,
      };

      final user = UserModel.fromMap(map, 'test_uid');

      expect(user.totalMessagesSent, 42);
      expect(user.totalMatches, 10);
      expect(user.totalDinners, 5);
    });

    test('should default totalMessagesSent to 0 if missing', () {
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
        'minAge': 20,
        'maxAge': 30,
        'budgetRange': 1,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        'subscription': 'free',
      };

      final user = UserModel.fromMap(map, 'test_uid');

      expect(user.totalMessagesSent, 0);
    });

    test('toMap should include totalMessagesSent', () {
      final user = UserModel(
        uid: 'test_uid',
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
        minAge: 20,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        totalMessagesSent: 100,
      );

      final map = user.toMap();

      expect(map['totalMessagesSent'], 100);
    });

    test('copyWith should update totalMessagesSent', () {
      final user = UserModel(
        uid: 'test_uid',
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
        minAge: 20,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        totalMessagesSent: 10,
      );

      final updatedUser = user.copyWith(totalMessagesSent: 20);

      expect(updatedUser.totalMessagesSent, 20);
      expect(updatedUser.name, user.name);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    test('should have notificationSettings with default values', () {
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
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      expect(user.notificationSettings, isNotNull);
      expect(user.notificationSettings['push_enabled'], isTrue);
      expect(user.notificationSettings['match_new'], isTrue);
      expect(user.notificationSettings['marketing_promo'], isFalse);
    });

    test('fromMap should parse notificationSettings', () {
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
        'isActive': true,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        'notificationSettings': {
          'push_enabled': false,
          'match_new': false,
        }
      };

      final user = UserModel.fromMap(map, 'test_uid');

      expect(user.notificationSettings['push_enabled'], isFalse);
      expect(user.notificationSettings['match_new'], isFalse);
      // Defaults that were not present in map should be null if not merged,
      // but my implementation creates a new map from the input.
      // If the input map doesn't contain a key, it will be null in the result map unless I merge with defaults.
      // Let's check my implementation.
    });

    test('toMap should include notificationSettings', () {
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
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      final map = user.toMap();
      expect(map['notificationSettings'], isNotNull);
      expect(map['notificationSettings']['push_enabled'], isTrue);
    });

    test('copyWith should update notificationSettings', () {
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
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      final updatedUser = user.copyWith(
        notificationSettings: {'push_enabled': false},
      );

      expect(updatedUser.notificationSettings['push_enabled'], isFalse);
    });
  });
}

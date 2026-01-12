import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    test('should have default notification settings', () {
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
      expect(user.notificationSettings['push_enabled'], true);
      expect(user.notificationSettings['match_new'], true);
    });

    test('fromMap should parse notification settings correctly', () {
      final map = {
        'uid': 'test_uid',
        'name': 'Test User',
        'email': 'test@example.com',
        'age': 25,
        'gender': 'male',
        'job': 'Developer',
        'interests': ['coding'],
        'country': 'Taiwan',
        'city': 'Taipei',
        'district': 'Xinyi',
        'preferredMatchType:': 'any',
        'minAge': 18,
        'maxAge': 30,
        'budgetRange': 1,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        'notificationSettings': {
          'push_enabled': false,
          'match_new': false,
        }
      };

      final user = UserModel.fromMap(map, 'test_uid');

      expect(user.notificationSettings['push_enabled'], false);
      expect(user.notificationSettings['match_new'], false);
      // Default should still be present for missing keys if we merge,
      // but current implementation in fromMap creates a fresh map with defaults
      // and overrides with values from map.
      expect(user.notificationSettings['match_success'], true);
    });

    test('toMap should include notification settings', () {
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
        notificationSettings: {
          'push_enabled': false,
        },
      );

      final map = user.toMap();
      expect(map['notificationSettings'], isNotNull);
      expect((map['notificationSettings'] as Map)['push_enabled'], false);
    });

    test('copyWith should update notification settings', () {
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

      expect(updatedUser.notificationSettings['push_enabled'], false);
    });
  });
}

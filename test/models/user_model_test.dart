import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel Tests', () {
    test('should have default privacy settings set to true', () {
      final user = UserModel(
        uid: '123',
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

      expect(user.isOnlineStatusVisible, true);
      expect(user.isLastSeenVisible, true);
    });

    test('should correctly deserialize privacy settings from Map', () {
      final map = {
        'name': 'Test User',
        'isOnlineStatusVisible': false,
        'isLastSeenVisible': false,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
      };

      final user = UserModel.fromMap(map, '123');

      expect(user.isOnlineStatusVisible, false);
      expect(user.isLastSeenVisible, false);
    });

    test('should correctly serialize privacy settings to Map', () {
      final user = UserModel(
        uid: '123',
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
        isOnlineStatusVisible: false,
        isLastSeenVisible: false,
      );

      final map = user.toMap();

      expect(map['isOnlineStatusVisible'], false);
      expect(map['isLastSeenVisible'], false);
    });

    test('copyWith should update privacy settings', () {
      final user = UserModel(
        uid: '123',
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
        isOnlineStatusVisible: false,
        isLastSeenVisible: false,
      );

      expect(updatedUser.isOnlineStatusVisible, false);
      expect(updatedUser.isLastSeenVisible, false);
    });
  });
}

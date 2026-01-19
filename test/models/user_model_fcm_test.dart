import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel FCM Token Tests', () {
    test('Should support fcmToken field in constructor and toMap', () {
      final user = UserModel(
        uid: 'test_uid',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Engineer',
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
        fcmToken: 'test_fcm_token',
      );

      expect(user.fcmToken, 'test_fcm_token');

      final map = user.toMap();
      expect(map['fcmToken'], 'test_fcm_token');
    });

    test('Should support fcmToken in fromMap', () {
      final map = {
        'name': 'Test User',
        'email': 'test@example.com',
        'age': 25,
        'gender': 'male',
        'job': 'Engineer',
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
        'fcmToken': 'token_from_map',
      };

      final user = UserModel.fromMap(map, 'test_uid');
      expect(user.fcmToken, 'token_from_map');
    });

    test('Should support null fcmToken', () {
      final map = {
        'name': 'Test User',
        'email': 'test@example.com',
        'age': 25,
        'gender': 'male',
        'job': 'Engineer',
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
        // fcmToken is missing
      };

      final user = UserModel.fromMap(map, 'test_uid');
      expect(user.fcmToken, null);
    });

    test('copyWith should update fcmToken', () {
      final user = UserModel(
        uid: 'test_uid',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Engineer',
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
        fcmToken: 'old_token',
      );

      final updatedUser = user.copyWith(fcmToken: 'new_token');
      expect(updatedUser.fcmToken, 'new_token');
      expect(updatedUser.name, 'Test User'); // Verify other fields remain unchanged
    });
  });
}

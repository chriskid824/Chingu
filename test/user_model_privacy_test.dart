import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel Privacy Settings', () {
    test('Should have default privacy settings as true', () {
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@test.com',
        age: 20,
        gender: 'male',
        job: 'dev',
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
      );

      expect(user.isOnlineStatusVisible, true);
      expect(user.isLastSeenVisible, true);
    });

    test('Should update privacy settings via copyWith', () {
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@test.com',
        age: 20,
        gender: 'male',
        job: 'dev',
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
      );

      final updated = user.copyWith(
        isOnlineStatusVisible: false,
        isLastSeenVisible: false,
      );

      expect(updated.isOnlineStatusVisible, false);
      expect(updated.isLastSeenVisible, false);
      // Ensure other fields are preserved
      expect(updated.name, 'Test');
    });

    test('toMap should include privacy settings', () {
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@test.com',
        age: 20,
        gender: 'male',
        job: 'dev',
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
        isOnlineStatusVisible: false,
        isLastSeenVisible: false,
      );

      final map = user.toMap();
      expect(map['isOnlineStatusVisible'], false);
      expect(map['isLastSeenVisible'], false);
    });

    test('fromMap should parse privacy settings', () {
      final map = {
        'name': 'Test',
        'email': 'test@test.com',
        'age': 20,
        'gender': 'male',
        'job': 'dev',
        'interests': [],
        'country': 'TW',
        'city': 'Taipei',
        'district': 'Xinyi',
        'preferredMatchType': 'any',
        'minAge': 18,
        'maxAge': 30,
        'budgetRange': 1,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        'isOnlineStatusVisible': false,
        'isLastSeenVisible': false,
      };

      final user = UserModel.fromMap(map, '123');
      expect(user.isOnlineStatusVisible, false);
      expect(user.isLastSeenVisible, false);
    });

    test('fromMap should default to true if fields are missing', () {
      final map = {
        'name': 'Test',
        'email': 'test@test.com',
        'age': 20,
        'gender': 'male',
        'job': 'dev',
        'interests': [],
        'country': 'TW',
        'city': 'Taipei',
        'district': 'Xinyi',
        'preferredMatchType': 'any',
        'minAge': 18,
        'maxAge': 30,
        'budgetRange': 1,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
      };

      final user = UserModel.fromMap(map, '123');
      expect(user.isOnlineStatusVisible, true);
      expect(user.isLastSeenVisible, true);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    final now = DateTime.now();
    final userMap = {
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
      'maxAge': 50,
      'budgetRange': 1,
      'isActive': true,
      'createdAt': Timestamp.fromDate(now),
      'lastLogin': Timestamp.fromDate(now),
      'subscription': 'free',
      'totalDinners': 5,
      'totalMatches': 10,
      'averageRating': 4.5,
      'notificationMatch': false,
      'notificationMessage': false,
      'notificationEvent': false,
      'isTwoFactorEnabled': false,
      'twoFactorMethod': 'email',
    };

    test('should parse from Map correctly', () {
      final user = UserModel.fromMap(userMap, 'user123');

      expect(user.uid, 'user123');
      expect(user.notificationMatch, false);
      expect(user.notificationMessage, false);
      expect(user.notificationEvent, false);
    });

    test('should use default values if fields are missing', () {
      final partialMap = Map<String, dynamic>.from(userMap);
      partialMap.remove('notificationMatch');
      partialMap.remove('notificationMessage');
      partialMap.remove('notificationEvent');

      final user = UserModel.fromMap(partialMap, 'user123');

      expect(user.notificationMatch, true);
      expect(user.notificationMessage, true);
      expect(user.notificationEvent, true);
    });

    test('toMap should include new fields', () {
      final user = UserModel(
        uid: 'user123',
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
        createdAt: now,
        lastLogin: now,
        notificationMatch: false,
        notificationMessage: false,
        notificationEvent: false,
      );

      final map = user.toMap();

      expect(map['notificationMatch'], false);
      expect(map['notificationMessage'], false);
      expect(map['notificationEvent'], false);
    });

    test('copyWith should update new fields', () {
      final user = UserModel(
        uid: 'user123',
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
        createdAt: now,
        lastLogin: now,
      );

      final updatedUser = user.copyWith(
        notificationMatch: false,
        notificationMessage: false,
        notificationEvent: false,
      );

      expect(updatedUser.notificationMatch, false);
      expect(updatedUser.notificationMessage, false);
      expect(updatedUser.notificationEvent, false);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    final mockDate = DateTime(2023, 1, 1);

    test('should have default notification settings set to true', () {
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
        createdAt: mockDate,
        lastLogin: mockDate,
      );

      expect(user.newMatchNotification, true);
      expect(user.newMessageNotification, true);
      expect(user.eventUpdateNotification, true);
    });

    test('fromMap should parse notification settings correctly', () {
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
        'createdAt': Timestamp.fromDate(mockDate),
        'lastLogin': Timestamp.fromDate(mockDate),
        'newMatchNotification': false,
        'newMessageNotification': false,
        'eventUpdateNotification': false,
      };

      final user = UserModel.fromMap(map, '123');

      expect(user.newMatchNotification, false);
      expect(user.newMessageNotification, false);
      expect(user.eventUpdateNotification, false);
    });

    test('fromMap should default notification settings to true if missing', () {
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
        'createdAt': Timestamp.fromDate(mockDate),
        'lastLogin': Timestamp.fromDate(mockDate),
      };

      final user = UserModel.fromMap(map, '123');

      expect(user.newMatchNotification, true);
      expect(user.newMessageNotification, true);
      expect(user.eventUpdateNotification, true);
    });

    test('toMap should include notification settings', () {
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
        createdAt: mockDate,
        lastLogin: mockDate,
        newMatchNotification: false,
        newMessageNotification: true,
        eventUpdateNotification: false,
      );

      final map = user.toMap();

      expect(map['newMatchNotification'], false);
      expect(map['newMessageNotification'], true);
      expect(map['eventUpdateNotification'], false);
    });

    test('copyWith should update notification settings', () {
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
        createdAt: mockDate,
        lastLogin: mockDate,
      );

      final updatedUser = user.copyWith(
        newMatchNotification: false,
        eventUpdateNotification: false,
      );

      expect(updatedUser.newMatchNotification, false);
      expect(updatedUser.newMessageNotification, true); // Should remain default/original
      expect(updatedUser.eventUpdateNotification, false);
    });
  });
}

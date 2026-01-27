import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    final mockDate = DateTime(2023, 1, 1);
    final mockTimestamp = Timestamp.fromDate(mockDate);

    test('should correctly parse hideOnlineStatus and hideLastSeen from map', () {
      final map = {
        'name': 'Test User',
        'email': 'test@example.com',
        'age': 25,
        'gender': 'male',
        'job': 'Developer',
        'interests': ['Coding'],
        'country': 'Taiwan',
        'city': 'Taipei',
        'district': 'Xinyi',
        'preferredMatchType': 'any',
        'minAge': 18,
        'maxAge': 30,
        'budgetRange': 1,
        'isActive': true,
        'createdAt': mockTimestamp,
        'lastLogin': mockTimestamp,
        'hideOnlineStatus': true,
        'hideLastSeen': true,
      };

      final user = UserModel.fromMap(map, 'test_uid');

      expect(user.hideOnlineStatus, true);
      expect(user.hideLastSeen, true);
    });

    test('should default hideOnlineStatus and hideLastSeen to false', () {
      final map = {
        'name': 'Test User',
        'email': 'test@example.com',
        'age': 25,
        'gender': 'male',
        'job': 'Developer',
        'interests': [],
        'country': 'Taiwan',
        'city': 'Taipei',
        'district': 'Xinyi',
        'preferredMatchType': 'any',
        'minAge': 18,
        'maxAge': 30,
        'budgetRange': 1,
        'isActive': true,
        'createdAt': mockTimestamp,
        'lastLogin': mockTimestamp,
      };

      final user = UserModel.fromMap(map, 'test_uid');

      expect(user.hideOnlineStatus, false);
      expect(user.hideLastSeen, false);
    });

    test('toMap should include privacy fields', () {
      final user = UserModel(
        uid: 'test_uid',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Developer',
        interests: [],
        country: 'Taiwan',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: mockDate,
        lastLogin: mockDate,
        hideOnlineStatus: true,
        hideLastSeen: true,
      );

      final map = user.toMap();

      expect(map['hideOnlineStatus'], true);
      expect(map['hideLastSeen'], true);
    });

    test('copyWith should update privacy fields', () {
      final user = UserModel(
        uid: 'test_uid',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Developer',
        interests: [],
        country: 'Taiwan',
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
        hideOnlineStatus: true,
        hideLastSeen: true,
      );

      expect(updatedUser.hideOnlineStatus, true);
      expect(updatedUser.hideLastSeen, true);
    });
  });
}

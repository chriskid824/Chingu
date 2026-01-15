import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel Privacy Settings', () {
    test('should have default privacy settings set to true', () {
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
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      expect(user.showOnlineStatus, true);
      expect(user.showLastSeen, true);
    });

    test('should correctly deserialize privacy settings from map', () {
      final map = {
        'name': 'Test User',
        'email': 'test@example.com',
        'showOnlineStatus': false,
        'showLastSeen': false,
      };

      final user = UserModel.fromMap(map, 'test_uid');

      expect(user.showOnlineStatus, false);
      expect(user.showLastSeen, false);
    });

    test('should correctly serialize privacy settings to map', () {
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
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        showOnlineStatus: false,
        showLastSeen: false,
      );

      final map = user.toMap();

      expect(map['showOnlineStatus'], false);
      expect(map['showLastSeen'], false);
    });

    test('copyWith should update privacy settings', () {
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
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      final updatedUser = user.copyWith(
        showOnlineStatus: false,
        showLastSeen: false,
      );

      expect(updatedUser.showOnlineStatus, false);
      expect(updatedUser.showLastSeen, false);
    });
  });
}

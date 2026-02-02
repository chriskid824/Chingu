import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    test('should have default notification settings set to true', () {
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

      expect(user.notificationMatches, true);
      expect(user.notificationMessages, true);
      expect(user.notificationEvents, true);
      expect(user.showMessagePreview, true);
    });

    test('fromMap should parse notification settings correctly', () {
      final map = {
        'uid': 'test_uid',
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
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        'notificationMatches': false,
        'notificationMessages': false,
        'notificationEvents': false,
        'showMessagePreview': false,
      };

      final user = UserModel.fromMap(map, 'test_uid');

      expect(user.notificationMatches, false);
      expect(user.notificationMessages, false);
      expect(user.notificationEvents, false);
      expect(user.showMessagePreview, false);
    });

    test('toMap should include notification settings', () {
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
        notificationMatches: false,
        notificationMessages: false,
        notificationEvents: false,
        showMessagePreview: false,
      );

      final map = user.toMap();

      expect(map['notificationMatches'], false);
      expect(map['notificationMessages'], false);
      expect(map['notificationEvents'], false);
      expect(map['showMessagePreview'], false);
    });

    test('copyWith should update notification settings', () {
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
        notificationMatches: false,
        notificationMessages: false,
        notificationEvents: false,
        showMessagePreview: false,
      );

      expect(updatedUser.notificationMatches, false);
      expect(updatedUser.notificationMessages, false);
      expect(updatedUser.notificationEvents, false);
      expect(updatedUser.showMessagePreview, false);
    });
  });
}

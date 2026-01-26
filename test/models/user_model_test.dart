import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel Notification Settings', () {
    final baseUserMap = {
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
      'isActive': true,
      'createdAt': Timestamp.now(),
      'lastLogin': Timestamp.now(),
      'subscription': 'free',
      'totalDinners': 0,
      'totalMatches': 0,
      'averageRating': 0.0,
      'isTwoFactorEnabled': false,
      'twoFactorMethod': 'email',
    };

    test('should have default notification settings as true', () {
      final user = UserModel.fromMap(baseUserMap, 'test_uid');

      expect(user.notificationMatchEnabled, true);
      expect(user.notificationMessageEnabled, true);
      expect(user.notificationEventEnabled, true);
      expect(user.notificationMarketingEnabled, true);
    });

    test('should parse notification settings from map', () {
      final map = Map<String, dynamic>.from(baseUserMap);
      map['notificationMatchEnabled'] = false;
      map['notificationMessageEnabled'] = false;
      map['notificationEventEnabled'] = false;
      map['notificationMarketingEnabled'] = false;

      final user = UserModel.fromMap(map, 'test_uid');

      expect(user.notificationMatchEnabled, false);
      expect(user.notificationMessageEnabled, false);
      expect(user.notificationEventEnabled, false);
      expect(user.notificationMarketingEnabled, false);
    });

    test('toMap should include notification settings', () {
      final user = UserModel(
        uid: 'test_uid',
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
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        notificationMatchEnabled: false,
        notificationMessageEnabled: false,
        notificationEventEnabled: false,
        notificationMarketingEnabled: false,
      );

      final map = user.toMap();

      expect(map['notificationMatchEnabled'], false);
      expect(map['notificationMessageEnabled'], false);
      expect(map['notificationEventEnabled'], false);
      expect(map['notificationMarketingEnabled'], false);
    });

    test('copyWith should update notification settings', () {
      final user = UserModel.fromMap(baseUserMap, 'test_uid');

      final updatedUser = user.copyWith(
        notificationMatchEnabled: false,
        notificationMessageEnabled: false,
      );

      expect(updatedUser.notificationMatchEnabled, false);
      expect(updatedUser.notificationMessageEnabled, false);
      expect(updatedUser.notificationEventEnabled, true); // Should remain default/original
      expect(updatedUser.notificationMarketingEnabled, true); // Should remain default/original
    });
  });
}

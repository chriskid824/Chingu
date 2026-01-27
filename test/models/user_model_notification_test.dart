import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';

void main() {
  group('UserModel Notification Fields Test', () {
    final DateTime now = DateTime.now();

    final UserModel user = UserModel(
      uid: 'test_uid',
      name: 'Test User',
      email: 'test@example.com',
      age: 25,
      gender: 'male',
      job: 'Tester',
      interests: ['testing'],
      country: 'Taiwan',
      city: 'Taipei',
      district: 'Xinyi',
      preferredMatchType: 'any',
      minAge: 18,
      maxAge: 30,
      budgetRange: 1,
      createdAt: now,
      lastLogin: now,
    );

    test('Default values should be true', () {
      expect(user.enablePushNotifications, isTrue);
      expect(user.enableMatchNotifications, isTrue);
      expect(user.enableMessageNotifications, isTrue);
      expect(user.enableEventNotifications, isTrue);
      expect(user.enableMarketingNotifications, isTrue);
    });

    test('toMap should include notification fields', () {
      final map = user.toMap();

      expect(map['enablePushNotifications'], isTrue);
      expect(map['enableMatchNotifications'], isTrue);
      expect(map['enableMessageNotifications'], isTrue);
      expect(map['enableEventNotifications'], isTrue);
      expect(map['enableMarketingNotifications'], isTrue);
    });

    test('fromMap should parse notification fields', () {
      final map = user.toMap();
      map['enablePushNotifications'] = false;
      map['enableMatchNotifications'] = false;
      map['enableMessageNotifications'] = true; // remains true

      final newUser = UserModel.fromMap(map, 'test_uid');

      expect(newUser.enablePushNotifications, isFalse);
      expect(newUser.enableMatchNotifications, isFalse);
      expect(newUser.enableMessageNotifications, isTrue);
      expect(newUser.enableEventNotifications, isTrue); // Default or from map
      expect(newUser.enableMarketingNotifications, isTrue);
    });

    test('copyWith should update notification fields', () {
      final updatedUser = user.copyWith(
        enableMatchNotifications: false,
        enableEventNotifications: false,
      );

      expect(updatedUser.enablePushNotifications, isTrue); // Unchanged
      expect(updatedUser.enableMatchNotifications, isFalse); // Changed
      expect(updatedUser.enableMessageNotifications, isTrue); // Unchanged
      expect(updatedUser.enableEventNotifications, isFalse); // Changed
      expect(updatedUser.enableMarketingNotifications, isTrue); // Unchanged
    });
  });
}

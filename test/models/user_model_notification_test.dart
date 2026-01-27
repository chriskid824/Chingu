import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';

void main() {
  group('Notification Preferences Tests', () {
    test('UserModel should serialize and deserialize notification preferences correctly', () {
      final user = UserModel(
        uid: 'test_uid',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Dev',
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
        enablePushNotifications: false,
        newMatchNotification: false,
        matchSuccessNotification: true,
        newMessageNotification: false,
        eventReminderNotification: true,
        eventUpdateNotification: false,
        marketingNotification: true,
        newsletterNotification: true,
      );

      final map = user.toMap();
      expect(map['enablePushNotifications'], false);
      expect(map['newMatchNotification'], false);
      expect(map['matchSuccessNotification'], true);
      expect(map['marketingNotification'], true);

      final newUser = UserModel.fromMap(map, 'test_uid');
      expect(newUser.enablePushNotifications, false);
      expect(newUser.newMatchNotification, false);
      expect(newUser.matchSuccessNotification, true);
      expect(newUser.marketingNotification, true);
    });

    test('UserModel defaults should be correct', () {
       final user = UserModel(
        uid: 'test_uid',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Dev',
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

      // Verify defaults
      expect(user.enablePushNotifications, true);
      expect(user.newMatchNotification, true);
      expect(user.matchSuccessNotification, true);
      expect(user.newMessageNotification, true);
      expect(user.eventReminderNotification, true);
      expect(user.eventUpdateNotification, true);
      expect(user.marketingNotification, false);
      expect(user.newsletterNotification, false);
    });

    test('UserModel copyWith should update preferences', () {
      final user = UserModel(
        uid: 'test_uid',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Dev',
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
        enablePushNotifications: false,
        marketingNotification: true,
      );

      expect(updated.enablePushNotifications, false);
      expect(updated.marketingNotification, true);
      expect(updated.newMatchNotification, true); // Should remain unchanged
    });
  });
}

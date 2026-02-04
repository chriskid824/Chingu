import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/models/notification_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  test('UserModel should correctly serialize and deserialize notificationPreferences', () {
    final now = DateTime.now();
    // Create a custom preference
    final preferences = NotificationPreferences(
      enablePushNotifications: false,
      newMatch: false,
      matchSuccess: true,
      newMessage: false,
      eventReminder: true,
      eventChanges: true,
      promotions: true,
      newsletter: true,
    );

    // Create user with custom preferences
    final user = UserModel(
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
      minAge: 20,
      maxAge: 30,
      budgetRange: 1,
      createdAt: now,
      lastLogin: now,
      notificationPreferences: preferences,
    );

    // Convert to map
    final map = user.toMap();

    // Verify map structure
    expect(map['notificationPreferences'], isA<Map<String, dynamic>>());
    expect(map['notificationPreferences']['enablePushNotifications'], false);
    expect(map['notificationPreferences']['matchSuccess'], true);

    // Create user from map
    final restoredUser = UserModel.fromMap(map, 'test_uid');

    // Verify restored preferences
    expect(restoredUser.notificationPreferences.enablePushNotifications, false);
    expect(restoredUser.notificationPreferences.matchSuccess, true);
    expect(restoredUser.notificationPreferences.promotions, true);
  });

  test('UserModel should use default preferences if missing in map', () {
    final now = DateTime.now();
    final map = {
      'name': 'Test User',
      'email': 'test@example.com',
      'createdAt': Timestamp.fromDate(now),
      'lastLogin': Timestamp.fromDate(now),
      // notificationPreferences missing
    };

    final user = UserModel.fromMap(map, 'test_uid');

    // Verify default preferences
    expect(user.notificationPreferences.enablePushNotifications, true);
    expect(user.notificationPreferences.promotions, false);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel Serialization', () {
    test('should serialize and deserialize NotificationSettings correctly', () {
      final settings = NotificationSettings(
        enablePushNotifications: false,
        newMatch: true,
        matchSuccess: false,
        newMessage: true,
        eventReminders: false,
        eventChanges: true,
        marketingPromotions: false,
        marketingNewsletter: true,
      );

      final map = settings.toMap();
      expect(map['enablePushNotifications'], false);
      expect(map['newMatch'], true);
      expect(map['matchSuccess'], false);

      final newSettings = NotificationSettings.fromMap(map);
      expect(newSettings.enablePushNotifications, false);
      expect(newSettings.newMatch, true);
      expect(newSettings.matchSuccess, false);
    });

    test('should handle UserModel with NotificationSettings', () {
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@test.com',
        age: 25,
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
        notificationSettings: NotificationSettings(
            newMessage: false
        ),
      );

      final map = user.toMap();
      expect(map['notificationSettings']['newMessage'], false);
      expect(map['notificationSettings']['newMatch'], true); // default

      final newUser = UserModel.fromMap(map, '123');
      expect(newUser.notificationSettings.newMessage, false);
      expect(newUser.notificationSettings.newMatch, true);
    });
  });
}

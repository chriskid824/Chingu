import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationSettings', () {
    test('defaults are correct', () {
      final settings = NotificationSettings();
      expect(settings.enablePushNotifications, true);
      expect(settings.newMatch, true);
      expect(settings.matchSuccess, true);
      expect(settings.newMessage, true);
      expect(settings.eventReminder, true);
      expect(settings.eventChange, true);
      expect(settings.promotions, false);
      expect(settings.newsletter, false);
    });

    test('fromMap and toMap work correctly', () {
      final map = {
        'enablePushNotifications': false,
        'newMatch': false,
        'matchSuccess': false,
        'newMessage': false,
        'eventReminder': false,
        'eventChange': false,
        'promotions': true,
        'newsletter': true,
      };

      final settings = NotificationSettings.fromMap(map);
      expect(settings.enablePushNotifications, false);
      expect(settings.promotions, true);

      final newMap = settings.toMap();
      expect(newMap, map);
    });

    test('copyWith works correctly', () {
      final settings = NotificationSettings();
      final newSettings = settings.copyWith(
        enablePushNotifications: false,
        promotions: true,
      );

      expect(newSettings.enablePushNotifications, false);
      expect(newSettings.promotions, true);
      expect(newSettings.newMatch, true); // should remain default
    });
  });

  group('UserModel', () {
    test('toMap includes notificationSettings', () {
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
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        notificationSettings: NotificationSettings(
          enablePushNotifications: false,
        ),
      );

      final map = user.toMap();
      expect(map['notificationSettings'], isNotNull);
      expect(map['notificationSettings']['enablePushNotifications'], false);
    });

    test('fromMap parses notificationSettings', () {
      final now = Timestamp.now();
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
        'isActive': true,
        'createdAt': now,
        'lastLogin': now,
        'subscription': 'free',
        'notificationSettings': {
          'enablePushNotifications': false,
          'promotions': true,
        }
      };

      final user = UserModel.fromMap(map, '123');
      expect(user.notificationSettings.enablePushNotifications, false);
      expect(user.notificationSettings.promotions, true);
      expect(user.notificationSettings.newMatch, true); // default
    });

    test('copyWith keeps notificationSettings if not provided', () {
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
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        notificationSettings: NotificationSettings(
          enablePushNotifications: false,
        ),
      );

      final updated = user.copyWith(name: 'New Name');
      expect(updated.name, 'New Name');
      expect(updated.notificationSettings.enablePushNotifications, false);
    });

     test('copyWith updates notificationSettings', () {
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
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      final updated = user.copyWith(
        notificationSettings: NotificationSettings(enablePushNotifications: false)
      );
      expect(updated.notificationSettings.enablePushNotifications, false);
    });
  });
}

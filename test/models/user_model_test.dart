import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/notification_settings_model.dart';

void main() {
  group('UserModel', () {
    test('toMap includes notificationSettings', () {
      final user = UserModel(
        uid: '123',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Engineer',
        interests: ['coding'],
        country: 'Taiwan',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        notificationSettings: const NotificationSettings(
          pushEnabled: false,
        ),
      );

      final map = user.toMap();
      expect(map['notificationSettings'], isA<Map>());
      expect(map['notificationSettings']['pushEnabled'], false);
    });

    test('fromMap parses notificationSettings', () {
      final map = {
        'name': 'Test',
        'email': 'test@test.com',
        'age': 20,
        'gender': 'male',
        'job': 'Student',
        'interests': [],
        'country': 'TW',
        'city': 'TPE',
        'district': 'Da-an',
        'preferredMatchType': 'any',
        'minAge': 18,
        'maxAge': 30,
        'budgetRange': 1,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        'notificationSettings': {
          'pushEnabled': false,
          'marketingPromo': true,
        },
      };

      final user = UserModel.fromMap(map, '123');
      expect(user.notificationSettings.pushEnabled, false);
      expect(user.notificationSettings.marketingPromo, true);
    });
  });
}

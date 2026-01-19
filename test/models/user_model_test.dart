import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    test('supports fcmToken', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: '123',
        name: 'Test',
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
        createdAt: now,
        lastLogin: now,
        fcmToken: 'token_123',
      );

      expect(user.fcmToken, 'token_123');

      final map = user.toMap();
      expect(map['fcmToken'], 'token_123');

      // Fix Timestamp for fromMap
      map['createdAt'] = Timestamp.fromDate(now);
      map['lastLogin'] = Timestamp.fromDate(now);

      final user2 = UserModel.fromMap(map, '123');
      expect(user2.fcmToken, 'token_123');

      final user3 = user.copyWith(fcmToken: 'new_token');
      expect(user3.fcmToken, 'new_token');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    test('supports subscription fields', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Dev',
        interests: ['Hiking'],
        country: 'TW',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: now,
        lastLogin: now,
        subscribedRegions: ['Taipei'],
        subscribedInterests: ['Hiking'],
      );

      final map = user.toMap();
      expect(map['subscribedRegions'], ['Taipei']);
      expect(map['subscribedInterests'], ['Hiking']);

      // Simulate Firestore retrieval where Timestamp is preserved
      // toMap converts DateTime to Timestamp
      expect(map['createdAt'], isA<Timestamp>());

      final user2 = UserModel.fromMap(map, '123');
      expect(user2.subscribedRegions, ['Taipei']);
      expect(user2.subscribedInterests, ['Hiking']);
    });

    test('defaults to empty lists', () {
       final now = DateTime.now();
       final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Dev',
        interests: ['Hiking'],
        country: 'TW',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: now,
        lastLogin: now,
      );

      expect(user.subscribedRegions, isEmpty);
      expect(user.subscribedInterests, isEmpty);
    });

    test('handles missing fields in fromMap', () {
       final now = DateTime.now();
       final map = {
         'name': 'Test',
         'email': 'test@example.com',
         'age': 25,
         'gender': 'male',
         'job': 'Dev',
         'interests': ['Hiking'],
         'country': 'TW',
         'city': 'Taipei',
         'district': 'Xinyi',
         'preferredMatchType': 'any',
         'minAge': 18,
         'maxAge': 30,
         'budgetRange': 1,
         'createdAt': Timestamp.fromDate(now),
         'lastLogin': Timestamp.fromDate(now),
         // missing subscribedRegions and subscribedInterests
       };

       final user = UserModel.fromMap(map, '123');
       expect(user.subscribedRegions, isEmpty);
       expect(user.subscribedInterests, isEmpty);
    });
  });
}

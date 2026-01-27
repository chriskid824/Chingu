import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';

void main() {
  group('UserModel Subscription Tests', () {
    final timestamp = Timestamp.now();
    final mockUserMap = {
      'name': 'Test User',
      'email': 'test@example.com',
      'age': 25,
      'gender': 'male',
      'job': 'Developer',
      'interests': ['Coding'],
      'country': 'Taiwan',
      'city': 'Taipei',
      'district': 'Xinyi',
      'preferredMatchType': 'any',
      'minAge': 18,
      'maxAge': 30,
      'budgetRange': 1,
      'isActive': true,
      'createdAt': timestamp,
      'lastLogin': timestamp,
      'subscribedTopics': ['region_taipei', 'interest_tech'],
    };

    test('should correctly parse subscribedTopics from map', () {
      final user = UserModel.fromMap(mockUserMap, 'user_id_123');
      expect(user.subscribedTopics, contains('region_taipei'));
      expect(user.subscribedTopics, contains('interest_tech'));
      expect(user.subscribedTopics.length, 2);
    });

    test('should serialize subscribedTopics to map', () {
      final user = UserModel(
        uid: 'user_id_123',
        name: 'Test',
        email: 'test@test.com',
        age: 20,
        gender: 'female',
        job: 'Designer',
        interests: [],
        country: 'Taiwan',
        city: 'Kaohsiung',
        district: 'Sanmin',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 99,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        subscribedTopics: ['region_kaohsiung', 'interest_art'],
      );

      final map = user.toMap();
      expect(map['subscribedTopics'], isA<List>());
      expect(map['subscribedTopics'], contains('region_kaohsiung'));
    });

    test('should handle missing subscribedTopics field gracefully', () {
      final mapWithoutTopics = Map<String, dynamic>.from(mockUserMap);
      mapWithoutTopics.remove('subscribedTopics');

      final user = UserModel.fromMap(mapWithoutTopics, 'uid');
      expect(user.subscribedTopics, isEmpty);
    });

    test('copyWith should update subscribedTopics', () {
      final user = UserModel.fromMap(mockUserMap, 'uid');
      final updatedUser = user.copyWith(
        subscribedTopics: ['region_taichung'],
      );

      expect(updatedUser.subscribedTopics, contains('region_taichung'));
      expect(updatedUser.subscribedTopics, isNot(contains('region_taipei')));
    });
  });
}

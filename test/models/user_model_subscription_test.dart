import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel Subscription Tests', () {
    final baseUserMap = {
      'name': 'Test User',
      'email': 'test@example.com',
      'age': 25,
      'gender': 'male',
      'job': 'Dev',
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
    };

    test('should initialize with empty subscribedTopics by default', () {
      final user = UserModel.fromMap(baseUserMap, 'user123');
      expect(user.subscribedTopics, isEmpty);
    });

    test('should load subscribedTopics from map', () {
      final map = Map<String, dynamic>.from(baseUserMap);
      map['subscribedTopics'] = ['topic_loc_taipei', 'topic_int_food'];

      final user = UserModel.fromMap(map, 'user123');
      expect(user.subscribedTopics, contains('topic_loc_taipei'));
      expect(user.subscribedTopics, contains('topic_int_food'));
      expect(user.subscribedTopics.length, 2);
    });

    test('toMap should include subscribedTopics', () {
      final user = UserModel.fromMap(baseUserMap, 'user123').copyWith(
        subscribedTopics: ['topic_loc_taichung'],
      );

      final map = user.toMap();
      expect(map['subscribedTopics'], contains('topic_loc_taichung'));
    });

    test('copyWith should update subscribedTopics', () {
      final user = UserModel.fromMap(baseUserMap, 'user123');
      final updatedUser = user.copyWith(subscribedTopics: ['topic_new']);

      expect(updatedUser.subscribedTopics, ['topic_new']);
      expect(user.subscribedTopics, isEmpty); // Original unchanged
    });
  });
}

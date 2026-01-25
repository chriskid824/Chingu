import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    final now = DateTime.now();
    final mockUserMap = {
      'name': 'Test User',
      'email': 'test@example.com',
      'age': 25,
      'gender': 'male',
      'job': 'Developer',
      'interests': ['coding'],
      'country': 'Taiwan',
      'city': 'Taipei',
      'district': 'Xinyi',
      'preferredMatchType': 'any',
      'minAge': 20,
      'maxAge': 30,
      'budgetRange': 1,
      'isActive': true,
      'createdAt': Timestamp.fromDate(now),
      'lastLogin': Timestamp.fromDate(now),
      'subscribedTopics': ['region_taipei', 'interest_tech'],
    };

    test('fromMap parses subscribedTopics correctly', () {
      final user = UserModel.fromMap(mockUserMap, 'user123');
      expect(user.subscribedTopics, containsAll(['region_taipei', 'interest_tech']));
    });

    test('fromMap handles missing subscribedTopics', () {
      final mapWithoutTopics = Map<String, dynamic>.from(mockUserMap);
      mapWithoutTopics.remove('subscribedTopics');
      final user = UserModel.fromMap(mapWithoutTopics, 'user123');
      expect(user.subscribedTopics, isEmpty);
    });

    test('toMap includes subscribedTopics', () {
      final user = UserModel.fromMap(mockUserMap, 'user123');
      final map = user.toMap();
      expect(map['subscribedTopics'], containsAll(['region_taipei', 'interest_tech']));
    });

    test('copyWith updates subscribedTopics', () {
      final user = UserModel.fromMap(mockUserMap, 'user123');
      final updatedUser = user.copyWith(subscribedTopics: ['region_kaohsiung']);
      expect(updatedUser.subscribedTopics, equals(['region_kaohsiung']));
    });
  });
}

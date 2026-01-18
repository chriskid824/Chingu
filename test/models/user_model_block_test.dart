import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel Blocked Users Test', () {
    final timestamp = Timestamp.now();
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
      'minAge': 18,
      'maxAge': 30,
      'budgetRange': 1,
      'isActive': true,
      'createdAt': timestamp,
      'lastLogin': timestamp,
      'blockedUsers': ['blocked1', 'blocked2'],
    };

    test('should parse blockedUsers from map', () {
      final user = UserModel.fromMap(mockUserMap, 'user123');
      expect(user.blockedUsers, contains('blocked1'));
      expect(user.blockedUsers, contains('blocked2'));
      expect(user.blockedUsers.length, 2);
    });

    test('should serialize blockedUsers to map', () {
      final user = UserModel.fromMap(mockUserMap, 'user123');
      final map = user.toMap();
      expect(map['blockedUsers'], contains('blocked1'));
      expect(map['blockedUsers'], contains('blocked2'));
    });

    test('should handle missing blockedUsers in map (default to empty)', () {
      final mapWithoutBlocked = Map<String, dynamic>.from(mockUserMap);
      mapWithoutBlocked.remove('blockedUsers');
      final user = UserModel.fromMap(mapWithoutBlocked, 'user123');
      expect(user.blockedUsers, isEmpty);
    });

    test('copyWith should update blockedUsers', () {
      final user = UserModel.fromMap(mockUserMap, 'user123');
      final updatedUser = user.copyWith(blockedUsers: ['blocked3']);
      expect(updatedUser.blockedUsers, equals(['blocked3']));
      expect(updatedUser.name, equals(user.name)); // Other fields remain same
    });
  });
}

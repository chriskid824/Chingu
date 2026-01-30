import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    final now = DateTime.now();
    final timestamp = Timestamp.fromDate(now);

    final userMap = {
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
      'createdAt': timestamp,
      'lastLogin': timestamp,
      'subscription': 'free',
      'totalDinners': 0,
      'totalMatches': 0,
      'averageRating': 0.0,
      'isTwoFactorEnabled': false,
      'twoFactorMethod': 'email',
      'enableMatchingNotifications': true,
      'enableMessageNotifications': false,
      'enableEventNotifications': true,
    };

    test('should create UserModel from Map', () {
      final user = UserModel.fromMap(userMap, 'user123');

      expect(user.uid, 'user123');
      expect(user.enableMatchingNotifications, true);
      expect(user.enableMessageNotifications, false);
      expect(user.enableEventNotifications, true);
    });

    test('should serialize to Map correctly', () {
      final user = UserModel.fromMap(userMap, 'user123');
      final map = user.toMap();

      expect(map['enableMatchingNotifications'], true);
      expect(map['enableMessageNotifications'], false);
      expect(map['enableEventNotifications'], true);
    });

    test('should handle missing notification fields with defaults', () {
      final partialMap = Map<String, dynamic>.from(userMap);
      partialMap.remove('enableMatchingNotifications');
      partialMap.remove('enableMessageNotifications');
      partialMap.remove('enableEventNotifications');

      final user = UserModel.fromMap(partialMap, 'user123');

      expect(user.enableMatchingNotifications, true);
      expect(user.enableMessageNotifications, true);
      expect(user.enableEventNotifications, true);
    });

    test('copyWith should update fields correctly', () {
      final user = UserModel.fromMap(userMap, 'user123');

      final updatedUser = user.copyWith(
        enableMessageNotifications: true,
        enableEventNotifications: false,
      );

      expect(updatedUser.enableMatchingNotifications, true); // Should remain same
      expect(updatedUser.enableMessageNotifications, true); // Updated
      expect(updatedUser.enableEventNotifications, false); // Updated
    });
  });
}

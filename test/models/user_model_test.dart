import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    final mockDate = DateTime(2023, 1, 1);
    final mockTimestamp = Timestamp.fromDate(mockDate);

    final baseMap = {
      'name': 'Test User',
      'email': 'test@example.com',
      'age': 25,
      'gender': 'male',
      'job': 'Developer',
      'interests': ['coding'],
      'country': 'Taiwan',
      'city': 'Taipei',
      'district': 'Xinyi',
      'bio': 'Hello',
      'avatarUrl': 'http://example.com/avatar.jpg',
      'preferredMatchType': 'any',
      'minAge': 18,
      'maxAge': 30,
      'budgetRange': 1,
      'isActive': true,
      'createdAt': mockTimestamp,
      'lastLogin': mockTimestamp,
      'subscription': 'free',
      'totalDinners': 5,
      'totalMatches': 10,
      'averageRating': 4.5,
      'isTwoFactorEnabled': false,
      'twoFactorMethod': 'email',
    };

    test('should support privacy settings fields', () {
      final map = Map<String, dynamic>.from(baseMap);
      map['showOnlineStatus'] = false;
      map['showLastSeen'] = false;

      final user = UserModel.fromMap(map, 'user_123');

      expect(user.showOnlineStatus, false);
      expect(user.showLastSeen, false);
    });

    test('should use default values for privacy settings if missing', () {
      final user = UserModel.fromMap(baseMap, 'user_123');

      expect(user.showOnlineStatus, true);
      expect(user.showLastSeen, true);
    });

    test('toMap should include privacy settings', () {
      final user = UserModel(
        uid: 'user_123',
        name: 'Test',
        email: 'test@test.com',
        age: 20,
        gender: 'female',
        job: 'Designer',
        interests: [],
        country: 'Taiwan',
        city: 'Taipei',
        district: 'Da-an',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: mockDate,
        lastLogin: mockDate,
        showOnlineStatus: false,
        showLastSeen: false,
      );

      final map = user.toMap();

      expect(map['showOnlineStatus'], false);
      expect(map['showLastSeen'], false);
    });

    test('copyWith should update privacy settings', () {
      final user = UserModel(
        uid: 'user_123',
        name: 'Test',
        email: 'test@test.com',
        age: 20,
        gender: 'female',
        job: 'Designer',
        interests: [],
        country: 'Taiwan',
        city: 'Taipei',
        district: 'Da-an',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: mockDate,
        lastLogin: mockDate,
      );

      final updatedUser = user.copyWith(
        showOnlineStatus: false,
        showLastSeen: false,
      );

      expect(updatedUser.showOnlineStatus, false);
      expect(updatedUser.showLastSeen, false);
      // Verify other fields remain unchanged (implicit check)
      expect(updatedUser.uid, user.uid);
    });
  });
}

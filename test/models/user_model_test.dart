import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    test('should correctly handle privacy fields', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: 'test_uid',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Developer',
        interests: ['coding'],
        country: 'Taiwan',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: now,
        lastLogin: now,
        hideOnlineStatus: true,
        hideLastSeen: true,
      );

      final map = user.toMap();
      expect(map['hideOnlineStatus'], true);
      expect(map['hideLastSeen'], true);
    });

    test('should use default values for privacy fields', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: 'uid2',
        name: 'User 2',
        email: 'u2@e.c',
        age: 20,
        gender: 'female',
        job: 'Des',
        interests: [],
        country: 'TW',
        city: 'TP',
        district: 'Da',
        preferredMatchType: 'any',
        minAge: 20,
        maxAge: 25,
        budgetRange: 1,
        createdAt: now,
        lastLogin: now,
      );

      expect(user.hideOnlineStatus, false);
      expect(user.hideLastSeen, false);

      final map = user.toMap();
      expect(map['hideOnlineStatus'], false);
      expect(map['hideLastSeen'], false);
    });

    test('copyWith should update privacy fields', () {
       final now = DateTime.now();
       final user = UserModel(
        uid: 'test_uid',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Developer',
        interests: ['coding'],
        country: 'Taiwan',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: now,
        lastLogin: now,
      );

      final updated = user.copyWith(hideOnlineStatus: true);
      expect(updated.hideOnlineStatus, true);
      expect(updated.hideLastSeen, false);

      final updated2 = updated.copyWith(hideLastSeen: true);
      expect(updated2.hideOnlineStatus, true);
      expect(updated2.hideLastSeen, true);
    });

    test('fromMap should parse privacy fields', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      final map = {
        'name': 'Test',
        'email': 't@e.c',
        'age': 30,
        'gender': 'male',
        'job': 'Job',
        'interests': [],
        'country': 'TW',
        'city': 'TP',
        'district': 'Dis',
        'preferredMatchType': 'any',
        'minAge': 20,
        'maxAge': 40,
        'budgetRange': 1,
        'isActive': true,
        'createdAt': timestamp,
        'lastLogin': timestamp,
        'hideOnlineStatus': true,
        'hideLastSeen': true,
      };

      final user = UserModel.fromMap(map, 'uid123');
      expect(user.hideOnlineStatus, true);
      expect(user.hideLastSeen, true);
    });
  });
}

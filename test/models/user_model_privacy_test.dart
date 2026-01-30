import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel Privacy Fields', () {
    final baseUser = UserModel(
      uid: '123',
      name: 'Test',
      email: 'test@test.com',
      age: 20,
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
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

    test('Defaults should be false', () {
      expect(baseUser.hideOnlineStatus, false);
      expect(baseUser.hideLastSeen, false);
    });

    test('Constructor should set values', () {
      // copyWith uses the constructor internally
      final user = baseUser.copyWith(
        hideOnlineStatus: true,
        hideLastSeen: true,
      );
      expect(user.hideOnlineStatus, true);
      expect(user.hideLastSeen, true);
    });

    test('toMap should include new fields', () {
      final user = baseUser.copyWith(
        hideOnlineStatus: true,
        hideLastSeen: true,
      );
      final map = user.toMap();
      expect(map['hideOnlineStatus'], true);
      expect(map['hideLastSeen'], true);
    });

    test('fromMap should parse new fields', () {
      final map = baseUser.toMap();
      map['hideOnlineStatus'] = true;
      map['hideLastSeen'] = true;

      // We need to ensure Timestamps are handled if we use the real fromMap which expects Map<String, dynamic>
      // The real fromMap casts createdAt to Timestamp.
      // In the test, toMap converts DateTime to Timestamp.
      // So map['createdAt'] is a Timestamp.

      final user = UserModel.fromMap(map, '123');
      expect(user.hideOnlineStatus, true);
      expect(user.hideLastSeen, true);
    });

    test('fromMap should handle missing fields (defaults)', () {
      final map = baseUser.toMap();
      map.remove('hideOnlineStatus');
      map.remove('hideLastSeen');

      final user = UserModel.fromMap(map, '123');
      expect(user.hideOnlineStatus, false);
      expect(user.hideLastSeen, false);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should have default privacy settings', () {
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@example.com',
        age: 20,
        gender: 'male',
        job: 'dev',
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

      expect(user.showOnlineStatus, true);
      expect(user.showLastSeen, true);
    });

    test('should serialize and deserialize privacy settings', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@example.com',
        age: 20,
        gender: 'male',
        job: 'dev',
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
        showOnlineStatus: false,
        showLastSeen: false,
      );

      final map = user.toMap();
      expect(map['showOnlineStatus'], false);
      expect(map['showLastSeen'], false);

      // Simulate Firestore return where Timestamp is used
      // However, toMap converts DateTime to Timestamp.
      // UserModel.fromMap expects Timestamp for date fields.
      // So we need to mock that behavior if we use fromMap directly with the output of toMap
      // AND checks date fields. But here we only check boolean fields.
      // The date fields might crash if we just pass map back to fromMap without converting Timestamps?
      // Let's check fromMap implementation.
      // It does: (map['createdAt'] as Timestamp).toDate()
      // toMap does: Timestamp.fromDate(createdAt)
      // So map['createdAt'] is Timestamp.
      // So passing map back to fromMap should work fine.

      final newUser = UserModel.fromMap(map, '123');
      expect(newUser.showOnlineStatus, false);
      expect(newUser.showLastSeen, false);
    });
  });
}

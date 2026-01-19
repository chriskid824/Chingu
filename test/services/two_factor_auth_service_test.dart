import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:chingu/services/firestore_service.dart';

// Simple mock for FirestoreService
class MockFirestoreService extends FirestoreService {
  final Map<String, Map<String, dynamic>> users = {};

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
     if (!users.containsKey(uid)) {
       users[uid] = {};
     }
     users[uid]!.addAll(data);
  }
}

void main() {
  group('TwoFactorAuthService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirestoreService mockFirestoreService;
    late TwoFactorAuthService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockFirestoreService = MockFirestoreService();
      service = TwoFactorAuthService(
        firestore: fakeFirestore,
        firestoreService: mockFirestoreService,
      );
    });

    test('sendVerificationCode should save code to firestore', () async {
      const target = 'test@example.com';
      await service.sendVerificationCode(target: target, method: 'email');

      final snapshot = await fakeFirestore.collection('two_factor_codes').doc(target).get();
      expect(snapshot.exists, isTrue);
      expect(snapshot.data()!['method'], equals('email'));
      expect(snapshot.data()!['code'], isNotNull);
      expect((snapshot.data()!['code'] as String).length, equals(6));
    });

    test('verifyCode should return true for correct code', () async {
      const target = 'test@example.com';
      await service.sendVerificationCode(target: target, method: 'email');

      final snapshot = await fakeFirestore.collection('two_factor_codes').doc(target).get();
      final code = snapshot.data()!['code'] as String;

      final result = await service.verifyCode(target, code);
      expect(result, isTrue);

      // Should be deleted after success
      final check = await fakeFirestore.collection('two_factor_codes').doc(target).get();
      expect(check.exists, isFalse);
    });

    test('verifyCode should return false for incorrect code and increment attempts', () async {
      const target = 'test@example.com';
      await service.sendVerificationCode(target: target, method: 'email');

      final result = await service.verifyCode(target, '000000'); // Assuming generated code is not 000000
      expect(result, isFalse);

      final snapshot = await fakeFirestore.collection('two_factor_codes').doc(target).get();
      expect(snapshot.data()!['attempts'], equals(1));
    });

    test('enableTwoFactor should update user in FirestoreService', () async {
      const uid = 'user123';
      await service.enableTwoFactor(uid, 'sms', phoneNumber: '123456');

      expect(mockFirestoreService.users[uid], isNotNull);
      expect(mockFirestoreService.users[uid]!['isTwoFactorEnabled'], isTrue);
      expect(mockFirestoreService.users[uid]!['twoFactorMethod'], equals('sms'));
      expect(mockFirestoreService.users[uid]!['phoneNumber'], equals('123456'));
    });

    test('disableTwoFactor should update user in FirestoreService', () async {
      const uid = 'user123';
      await service.disableTwoFactor(uid);

      expect(mockFirestoreService.users[uid], isNotNull);
      expect(mockFirestoreService.users[uid]!['isTwoFactorEnabled'], isFalse);
    });
  });
}

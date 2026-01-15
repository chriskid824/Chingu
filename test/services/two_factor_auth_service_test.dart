import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Manual Fake for FirestoreService to avoid complexity with Mockito generation in this env
class FakeFirestoreService extends FirestoreService {
  final Map<String, Map<String, dynamic>> _users = {};

  FakeFirestoreService({super.firestore});

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    if (!_users.containsKey(uid)) {
      _users[uid] = {};
    }
    _users[uid]!.addAll(data);
  }

  // Helper to verify state
  Map<String, dynamic>? getUserData(String uid) {
    return _users[uid];
  }
}

void main() {
  group('TwoFactorAuthService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FakeFirestoreService fakeFirestoreService;
    late TwoFactorAuthService twoFactorAuthService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      fakeFirestoreService = FakeFirestoreService(firestore: fakeFirestore);
      twoFactorAuthService = TwoFactorAuthService(
        firestore: fakeFirestore,
        firestoreService: fakeFirestoreService,
      );
    });

    test('sendVerificationCode creates a code document in Firestore', () async {
      const target = 'test@example.com';
      await twoFactorAuthService.sendVerificationCode(
        target: target,
        method: 'email',
        uid: 'user1',
      );

      final doc = await fakeFirestore
          .collection('two_factor_codes')
          .doc(target)
          .get();

      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['method'], 'email');
      expect(data['uid'], 'user1');
      expect(data['code'], isNotNull);
      expect((data['code'] as String).length, 6);
    });

    test('verifyCode returns true for correct code', () async {
      const target = 'test@example.com';
      // First send code
      await twoFactorAuthService.sendVerificationCode(
        target: target,
        method: 'email',
      );

      // Get the code manually
      final doc = await fakeFirestore
          .collection('two_factor_codes')
          .doc(target)
          .get();
      final code = doc.data()!['code'] as String;

      // Verify
      final result = await twoFactorAuthService.verifyCode(target, code);
      expect(result, true);

      // Should be deleted after success
      final docAfter = await fakeFirestore
          .collection('two_factor_codes')
          .doc(target)
          .get();
      expect(docAfter.exists, false);
    });

    test('verifyCode returns false and increments attempts for incorrect code', () async {
      const target = 'test@example.com';
      await twoFactorAuthService.sendVerificationCode(
        target: target,
        method: 'email',
      );

      final result = await twoFactorAuthService.verifyCode(target, '000000');
      expect(result, false);

      final doc = await fakeFirestore
          .collection('two_factor_codes')
          .doc(target)
          .get();
      expect(doc.data()!['attempts'], 1);
    });

    test('enableTwoFactor updates user data via FirestoreService', () async {
      const uid = 'user1';
      await twoFactorAuthService.enableTwoFactor(uid, 'sms', phoneNumber: '+1234567890');

      final userData = fakeFirestoreService.getUserData(uid);
      expect(userData, isNotNull);
      expect(userData!['isTwoFactorEnabled'], true);
      expect(userData['twoFactorMethod'], 'sms');
      expect(userData['phoneNumber'], '+1234567890');
    });

    test('enableTwoFactor throws if sms method has no phone number', () async {
      const uid = 'user1';
      expect(
        () => twoFactorAuthService.enableTwoFactor(uid, 'sms'),
        throwsException,
      );
    });

    test('disableTwoFactor updates user data', () async {
      const uid = 'user1';
      // Enable first
      await twoFactorAuthService.enableTwoFactor(uid, 'email');

      // Disable
      await twoFactorAuthService.disableTwoFactor(uid);

      final userData = fakeFirestoreService.getUserData(uid);
      expect(userData!['isTwoFactorEnabled'], false);
    });
  });
}

import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService firestoreService;
  late TwoFactorAuthService twoFactorAuthService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
    twoFactorAuthService = TwoFactorAuthService(
      firestore: fakeFirestore,
      firestoreService: firestoreService,
    );
  });

  group('TwoFactorAuthService', () {
    const String targetEmail = 'test@example.com';
    const String targetPhone = '+886912345678';
    const String userId = 'user_123';

    test('sendVerificationCode creates a document in Firestore', () async {
      await twoFactorAuthService.sendVerificationCode(
        target: targetEmail,
        method: 'email',
        uid: userId,
      );

      final doc = await fakeFirestore
          .collection('two_factor_codes')
          .doc(targetEmail)
          .get();

      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['method'], 'email');
      expect(data['uid'], userId);
      expect(data['code'], isA<String>());
      expect((data['code'] as String).length, 6);
      expect(data['attempts'], 0);
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['expiresAt'], isA<Timestamp>());
    });

    test('verifyCode returns true and deletes document on success', () async {
      // Setup: Create a valid code
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      await fakeFirestore.collection('two_factor_codes').doc(targetEmail).set({
        'code': '123456',
        'method': 'email',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 0,
      });

      final result =
          await twoFactorAuthService.verifyCode(targetEmail, '123456');

      expect(result, isTrue);

      // Verify document is deleted
      final doc = await fakeFirestore
          .collection('two_factor_codes')
          .doc(targetEmail)
          .get();
      expect(doc.exists, isFalse);
    });

    test('verifyCode returns false and increments attempts on wrong code',
        () async {
      // Setup
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      await fakeFirestore.collection('two_factor_codes').doc(targetEmail).set({
        'code': '123456',
        'method': 'email',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 0,
      });

      final result =
          await twoFactorAuthService.verifyCode(targetEmail, '654321');

      expect(result, isFalse);

      // Verify attempts incremented
      final doc = await fakeFirestore
          .collection('two_factor_codes')
          .doc(targetEmail)
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['attempts'], 1);
    });

    test('verifyCode throws exception if code is expired', () async {
      // Setup: Expired code
      final expiresAt = DateTime.now().subtract(const Duration(minutes: 1));
      await fakeFirestore.collection('two_factor_codes').doc(targetEmail).set({
        'code': '123456',
        'method': 'email',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 0,
      });

      expect(
        () => twoFactorAuthService.verifyCode(targetEmail, '123456'),
        throwsA(isA<Exception>()),
      );
    });

    test('verifyCode throws exception if too many attempts', () async {
      // Setup: Max attempts
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      await fakeFirestore.collection('two_factor_codes').doc(targetEmail).set({
        'code': '123456',
        'method': 'email',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 5,
      });

      expect(
        () => twoFactorAuthService.verifyCode(targetEmail, '123456'),
        throwsA(isA<Exception>()),
      );
    });

    test('enableTwoFactor updates user document', () async {
      // Setup: Create user
      await fakeFirestore.collection('users').doc(userId).set({
        'name': 'Test User',
        'isTwoFactorEnabled': false,
      });

      await twoFactorAuthService.enableTwoFactor(
        userId,
        'sms',
        phoneNumber: targetPhone,
      );

      final doc = await fakeFirestore.collection('users').doc(userId).get();
      expect(doc.data()!['isTwoFactorEnabled'], isTrue);
      expect(doc.data()!['twoFactorMethod'], 'sms');
      expect(doc.data()!['phoneNumber'], targetPhone);
    });

    test('enableTwoFactor throws if sms selected but no phone provided',
        () async {
      expect(
        () => twoFactorAuthService.enableTwoFactor(userId, 'sms'),
        throwsA(isA<Exception>()),
      );
    });

    test('disableTwoFactor updates user document', () async {
      // Setup: Create user with 2FA enabled
      await fakeFirestore.collection('users').doc(userId).set({
        'name': 'Test User',
        'isTwoFactorEnabled': true,
        'twoFactorMethod': 'sms',
      });

      await twoFactorAuthService.disableTwoFactor(userId);

      final doc = await fakeFirestore.collection('users').doc(userId).get();
      expect(doc.data()!['isTwoFactorEnabled'], isFalse);
    });
  });
}

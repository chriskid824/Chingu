import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('TwoFactorAuthService', () {
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

    const targetEmail = 'test@example.com';
    const collection = 'two_factor_codes';

    test('sendVerificationCode creates document with code', () async {
      await twoFactorAuthService.sendVerificationCode(
        target: targetEmail,
        method: 'email',
      );

      final doc = await fakeFirestore.collection(collection).doc(targetEmail).get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['method'], 'email');
      expect(data['attempts'], 0);
      expect(data['code'], isNotNull);
      expect((data['code'] as String).length, 6);
      expect(data['expiresAt'], isNotNull);
    });

    test('verifyCode returns true and deletes document on success', () async {
      // Setup
      final code = '123456';
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      await fakeFirestore.collection(collection).doc(targetEmail).set({
        'code': code,
        'method': 'email',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 0,
      });

      // Execute
      final result = await twoFactorAuthService.verifyCode(targetEmail, code);

      // Verify
      expect(result, isTrue);
      final doc = await fakeFirestore.collection(collection).doc(targetEmail).get();
      expect(doc.exists, isFalse);
    });

    test('verifyCode returns false and increments attempts on wrong code', () async {
      // Setup
      final code = '123456';
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      await fakeFirestore.collection(collection).doc(targetEmail).set({
        'code': code,
        'method': 'email',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 0,
      });

      // Execute
      final result = await twoFactorAuthService.verifyCode(targetEmail, '654321');

      // Verify
      expect(result, isFalse);
      final doc = await fakeFirestore.collection(collection).doc(targetEmail).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['attempts'], 1);
    });

    test('verifyCode throws exception if expired', () async {
      // Setup
      final code = '123456';
      final expiresAt = DateTime.now().subtract(const Duration(minutes: 1)); // Expired
      await fakeFirestore.collection(collection).doc(targetEmail).set({
        'code': code,
        'method': 'email',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 0,
      });

      // Execute & Verify
      expect(
        twoFactorAuthService.verifyCode(targetEmail, code),
        throwsException,
      );
    });

    test('verifyCode throws exception if too many attempts', () async {
      // Setup
      final code = '123456';
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      await fakeFirestore.collection(collection).doc(targetEmail).set({
        'code': code,
        'method': 'email',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 5, // Limit reached
      });

      // Execute & Verify
      expect(
        twoFactorAuthService.verifyCode(targetEmail, code),
        throwsException,
      );
    });

    test('enableTwoFactor updates user document', () async {
      // Setup user
      final uid = 'user123';
      await fakeFirestore.collection('users').doc(uid).set({
        'name': 'Test User',
        'isTwoFactorEnabled': false,
      });

      // Execute
      await twoFactorAuthService.enableTwoFactor(uid, 'sms', phoneNumber: '+1234567890');

      // Verify
      final doc = await fakeFirestore.collection('users').doc(uid).get();
      final data = doc.data()!;
      expect(data['isTwoFactorEnabled'], isTrue);
      expect(data['twoFactorMethod'], 'sms');
      expect(data['phoneNumber'], '+1234567890');
    });

    test('disableTwoFactor updates user document', () async {
      // Setup user
      final uid = 'user123';
      await fakeFirestore.collection('users').doc(uid).set({
        'name': 'Test User',
        'isTwoFactorEnabled': true,
        'twoFactorMethod': 'sms',
      });

      // Execute
      await twoFactorAuthService.disableTwoFactor(uid);

      // Verify
      final doc = await fakeFirestore.collection('users').doc(uid).get();
      final data = doc.data()!;
      expect(data['isTwoFactorEnabled'], isFalse);
    });
  });
}

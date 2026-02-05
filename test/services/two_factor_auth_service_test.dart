import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TwoFactorAuthService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TwoFactorAuthService service;
    late FirestoreService firestoreService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      firestoreService = FirestoreService(firestore: fakeFirestore);
      service = TwoFactorAuthService(
        firestore: fakeFirestore,
        firestoreService: firestoreService,
      );
    });

    test('sendVerificationCode should create a document in firestore', () async {
      const email = 'test@example.com';
      await service.sendVerificationCode(
        target: email,
        method: TwoFactorMethod.email,
        uid: 'user123',
      );

      final doc = await fakeFirestore
          .collection('two_factor_codes')
          .doc(email)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['method'], equals('email'));
      expect(doc.data()!['code'], isNotNull);
      expect(doc.data()!['attempts'], equals(0));
    });

    test('verifyCode should return true for correct code', () async {
      const email = 'test@example.com';
      // First send code
      await service.sendVerificationCode(
        target: email,
        method: TwoFactorMethod.email,
      );

      // Get the code manually from firestore
      final doc = await fakeFirestore
          .collection('two_factor_codes')
          .doc(email)
          .get();
      final code = doc.data()!['code'] as String;

      // Verify
      final result = await service.verifyCode(email, code);
      expect(result, isTrue);

      // Verify document is deleted
      final docAfter = await fakeFirestore
          .collection('two_factor_codes')
          .doc(email)
          .get();
      expect(docAfter.exists, isFalse);
    });

    test('verifyCode should return false for incorrect code and increment attempts', () async {
      const email = 'test@example.com';
      await service.sendVerificationCode(
        target: email,
        method: TwoFactorMethod.email,
      );

      final result = await service.verifyCode(email, '000000');
      expect(result, isFalse);

      final doc = await fakeFirestore
          .collection('two_factor_codes')
          .doc(email)
          .get();
      expect(doc.data()!['attempts'], equals(1));
    });

    test('enableTwoFactor should update user document', () async {
      const uid = 'user123';
      // Create user first
      await fakeFirestore.collection('users').doc(uid).set({
        'name': 'Test User',
        'isTwoFactorEnabled': false,
      });

      await service.enableTwoFactor(uid, TwoFactorMethod.sms, phoneNumber: '+1234567890');

      final userDoc = await fakeFirestore.collection('users').doc(uid).get();
      expect(userDoc.data()!['isTwoFactorEnabled'], isTrue);
      expect(userDoc.data()!['twoFactorMethod'], equals('sms'));
      expect(userDoc.data()!['phoneNumber'], equals('+1234567890'));
    });

    test('sendVerificationCode should validate email format', () async {
      expect(
        () => service.sendVerificationCode(
          target: 'invalid-email',
          method: TwoFactorMethod.email,
        ),
        throwsException,
      );
    });
  });
}

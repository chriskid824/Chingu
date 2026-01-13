import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'two_factor_auth_service_test.mocks.dart';

@GenerateMocks([FirestoreService])
void main() {
  late TwoFactorAuthService twoFactorAuthService;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirestoreService mockFirestoreService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFirestoreService = MockFirestoreService();
    twoFactorAuthService = TwoFactorAuthService(
      firestore: fakeFirestore,
      firestoreService: mockFirestoreService,
    );
  });

  group('TwoFactorAuthService', () {
    const target = 'test@example.com';
    const method = 'email';

    test('sendVerificationCode should store code in Firestore', () async {
      await twoFactorAuthService.sendVerificationCode(
        target: target,
        method: method,
      );

      final doc = await fakeFirestore
          .collection('two_factor_codes')
          .doc(target)
          .get();

      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['method'], equals(method));
      expect(data['code'], isNotNull);
      expect((data['code'] as String).length, equals(6));
      expect(data['attempts'], equals(0));
    });

    test('verifyCode should return true for correct code', () async {
      // First send code
      await twoFactorAuthService.sendVerificationCode(
        target: target,
        method: method,
      );

      // Get the code directly from firestore
      final doc = await fakeFirestore
          .collection('two_factor_codes')
          .doc(target)
          .get();
      final code = doc.data()!['code'] as String;

      // Verify
      final result = await twoFactorAuthService.verifyCode(target, code);
      expect(result, isTrue);

      // Verify document is deleted
      final docAfter = await fakeFirestore
          .collection('two_factor_codes')
          .doc(target)
          .get();
      expect(docAfter.exists, isFalse);
    });

    test('verifyCode should return false for incorrect code and increment attempts', () async {
      // First send code
      await twoFactorAuthService.sendVerificationCode(
        target: target,
        method: method,
      );

      // Verify with wrong code
      final result = await twoFactorAuthService.verifyCode(target, '000000');
      expect(result, isFalse);

      // Check attempts incremented
      final doc = await fakeFirestore
          .collection('two_factor_codes')
          .doc(target)
          .get();
      expect(doc.data()!['attempts'], equals(1));
    });

    test('verifyCode should throw exception if attempts exceeded', () async {
      // First send code
      await twoFactorAuthService.sendVerificationCode(
        target: target,
        method: method,
      );

      // Manually set attempts to 5
      await fakeFirestore
          .collection('two_factor_codes')
          .doc(target)
          .update({'attempts': 5});

      // Verify with correct code should fail due to attempts
      final doc = await fakeFirestore
          .collection('two_factor_codes')
          .doc(target)
          .get();
      final code = doc.data()!['code'] as String;

      expect(
        () => twoFactorAuthService.verifyCode(target, code),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('嘗試次數過多'))),
      );
    });

    test('verifyCode should throw exception if expired', () async {
      // Manually create an expired code
      final expiredTime = DateTime.now().subtract(const Duration(minutes: 1));
      await fakeFirestore.collection('two_factor_codes').doc(target).set({
        'code': '123456',
        'method': method,
        'expiresAt': Timestamp.fromDate(expiredTime),
        'createdAt': FieldValue.serverTimestamp(),
        'attempts': 0,
      });

      expect(
        () => twoFactorAuthService.verifyCode(target, '123456'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('驗證碼已過期'))),
      );
    });

    test('enableTwoFactor should update user in FirestoreService', () async {
      const uid = 'user123';

      await twoFactorAuthService.enableTwoFactor(uid, 'email');

      verify(mockFirestoreService.updateUser(uid, {
        'isTwoFactorEnabled': true,
        'twoFactorMethod': 'email',
      })).called(1);
    });

    test('enableTwoFactor should require phone number for SMS', () async {
      const uid = 'user123';

      expect(
        () => twoFactorAuthService.enableTwoFactor(uid, 'sms'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('啟用 SMS 驗證需要電話號碼'))),
      );
    });

    test('enableTwoFactor should update phone number for SMS', () async {
      const uid = 'user123';
      const phone = '+886912345678';

      await twoFactorAuthService.enableTwoFactor(uid, 'sms', phoneNumber: phone);

      verify(mockFirestoreService.updateUser(uid, {
        'isTwoFactorEnabled': true,
        'twoFactorMethod': 'sms',
        'phoneNumber': phone,
      })).called(1);
    });

    test('disableTwoFactor should update user in FirestoreService', () async {
      const uid = 'user123';

      await twoFactorAuthService.disableTwoFactor(uid);

      verify(mockFirestoreService.updateUser(uid, {
        'isTwoFactorEnabled': false,
      })).called(1);
    });
  });
}

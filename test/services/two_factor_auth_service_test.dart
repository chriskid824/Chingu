import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@GenerateMocks([FirestoreService])
import 'two_factor_auth_service_test.mocks.dart';

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

    test('sendVerificationCode should store code in Firestore', () async {
      const target = 'test@example.com';
      const method = 'email';

      await service.sendVerificationCode(
        target: target,
        method: method,
      );

      final snapshot = await fakeFirestore
          .collection('two_factor_codes')
          .doc(target)
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()!['method'], equals(method));
      expect(snapshot.data()!['code'], isNotNull);
      expect((snapshot.data()!['code'] as String).length, equals(6));
    });

    test('verifyCode should return true for correct code', () async {
      const target = 'test@example.com';
      const code = '123456';

      // Setup data
      await fakeFirestore.collection('two_factor_codes').doc(target).set({
        'code': code,
        'method': 'email',
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 10))),
        'attempts': 0,
      });

      final result = await service.verifyCode(target, code);
      expect(result, isTrue);

      // Verify code is deleted after success
      final snapshot = await fakeFirestore.collection('two_factor_codes').doc(target).get();
      expect(snapshot.exists, isFalse);
    });

    test('verifyCode should return false for incorrect code and increment attempts', () async {
      const target = 'test@example.com';
      const correctCode = '123456';

      // Setup data
      await fakeFirestore.collection('two_factor_codes').doc(target).set({
        'code': correctCode,
        'method': 'email',
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 10))),
        'attempts': 0,
      });

      final result = await service.verifyCode(target, '000000');
      expect(result, isFalse);

      // Verify attempts incremented
      final snapshot = await fakeFirestore.collection('two_factor_codes').doc(target).get();
      expect(snapshot.exists, isTrue);
      expect(snapshot.data()!['attempts'], equals(1));
    });

    test('verifyCode should throw exception if expired', () async {
      const target = 'test@example.com';
      const code = '123456';

      // Setup expired data
      await fakeFirestore.collection('two_factor_codes').doc(target).set({
        'code': code,
        'method': 'email',
        'expiresAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 1))),
        'attempts': 0,
      });

      expect(
        () => service.verifyCode(target, code),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('驗證碼已過期'))),
      );
    });

    test('enableTwoFactor should call updateUser', () async {
      const uid = 'user123';
      const method = 'sms';
      const phone = '+1234567890';

      // Stub updateUser
      when(mockFirestoreService.updateUser(any, any)).thenAnswer((_) async {});

      await service.enableTwoFactor(uid, method, phoneNumber: phone);

      verify(mockFirestoreService.updateUser(uid, {
        'isTwoFactorEnabled': true,
        'twoFactorMethod': method,
        'phoneNumber': phone,
      })).called(1);
    });

    test('disableTwoFactor should call updateUser', () async {
      const uid = 'user123';

      // Stub updateUser
      when(mockFirestoreService.updateUser(any, any)).thenAnswer((_) async {});

      await service.disableTwoFactor(uid);

      verify(mockFirestoreService.updateUser(uid, {
        'isTwoFactorEnabled': false,
      })).called(1);
    });
  });
}

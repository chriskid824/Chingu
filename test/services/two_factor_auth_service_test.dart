import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:chingu/services/firestore_service.dart';

@GenerateMocks([FirebaseAuth, FirestoreService, UserCredential, User, PhoneAuthCredential])
import 'two_factor_auth_service_test.mocks.dart';

void main() {
  late TwoFactorAuthService service;
  late MockFirebaseAuth mockAuth;
  late MockFirestoreService mockFirestoreService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestoreService = MockFirestoreService();
    fakeFirestore = FakeFirebaseFirestore();

    service = TwoFactorAuthService(
      firestore: fakeFirestore,
      firestoreService: mockFirestoreService,
      auth: mockAuth,
    );
  });

  group('TwoFactorAuthService', () {
    test('sendVerificationCode (Email) stores code in Firestore', () async {
      final target = 'test@example.com';
      final method = 'email';

      await service.sendVerificationCode(target: target, method: method);

      final doc = await fakeFirestore.collection('two_factor_codes').doc(target).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['method'], equals('email'));
      expect(doc.data()!['code'], isNotNull);
    });

    test('sendVerificationCode (SMS) calls verifyPhoneNumber', () async {
      final target = '+1234567890';
      final method = 'sms';

      // Mock verifyPhoneNumber
      // Note: verifyPhoneNumber is void, but takes callbacks.
      // We need to simulate the callbacks being called.

      when(mockAuth.verifyPhoneNumber(
        phoneNumber: anyNamed('phoneNumber'),
        verificationCompleted: anyNamed('verificationCompleted'),
        verificationFailed: anyNamed('verificationFailed'),
        codeSent: anyNamed('codeSent'),
        codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
      )).thenAnswer((invocation) async {
        // Retrieve the callback and invoke it
        final codeSent = invocation.namedArguments[Symbol('codeSent')] as void Function(String, int?);
        codeSent('test_verification_id', null);
        return;
      });

      final result = await service.sendVerificationCode(target: target, method: method);

      expect(result, equals('test_verification_id'));

      verify(mockAuth.verifyPhoneNumber(
        phoneNumber: target,
        verificationCompleted: anyNamed('verificationCompleted'),
        verificationFailed: anyNamed('verificationFailed'),
        codeSent: anyNamed('codeSent'),
        codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
      )).called(1);
    });

    test('verifyCode (Email) verifies correctly', () async {
      final target = 'test@example.com';
      final method = 'email';

      // 1. Manually insert a code
      await fakeFirestore.collection('two_factor_codes').doc(target).set({
        'code': '123456',
        'method': method,
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)),
        'attempts': 0,
      });

      // 2. Verify with correct code
      final result = await service.verifyCode(target, '123456');
      expect(result, isTrue);

      // 3. Verify doc is deleted
      final doc = await fakeFirestore.collection('two_factor_codes').doc(target).get();
      expect(doc.exists, isFalse);
    });

    test('verifyCode (SMS) calls signInWithCredential', () async {
      final target = '+1234567890';
      final code = '123456';
      final verificationId = 'test_verification_id';

      // Mock signInWithCredential
      final mockUserCredential = MockUserCredential();
      when(mockAuth.signInWithCredential(any)).thenAnswer((_) async => mockUserCredential);

      final result = await service.verifyCode(target, code, verificationId: verificationId);

      expect(result, isTrue);
      verify(mockAuth.signInWithCredential(any)).called(1);
    });
  });
}

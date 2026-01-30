import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'two_factor_auth_service_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  User,
  UserCredential,
  FirebaseFunctions,
  HttpsCallable,
  HttpsCallableResult
])
void main() {
  late TwoFactorAuthService service;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseFunctions mockFunctions;
  late MockUser mockUser;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult mockCallableResult;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    mockUser = MockUser();
    mockCallable = MockHttpsCallable();
    mockCallableResult = MockHttpsCallableResult();

    service = TwoFactorAuthService(
      auth: mockAuth,
      firestore: fakeFirestore,
      functions: mockFunctions,
    );

    // Default mock behavior
    when(mockAuth.currentUser).thenReturn(mockUser);
  });

  group('TwoFactorAuthService', () {
    group('sendVerificationCode', () {
      test('SMS: calls verifyPhoneNumber', () async {
        final contact = '+1234567890';
        var codeSentCalled = false;

        // verifyPhoneNumber is a bit tricky to mock because it uses named parameters and callbacks.
        // We need to capture the callbacks or just verify it was called.
        // Mockito verify works for named params.

        when(mockAuth.verifyPhoneNumber(
          phoneNumber: contact,
          verificationCompleted: anyNamed('verificationCompleted'),
          verificationFailed: anyNamed('verificationFailed'),
          codeSent: anyNamed('codeSent'),
          codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        )).thenAnswer((invocation) async {
           // Simulate success by calling codeSent manually if we could capture it.
           // Since we can't easily capture named args in 'thenAnswer' (Invocation usually has positional/named),
           // we'll just verify the call happened.
           // However, if we want to test the callback execution, we need to extract the callback.
           final codeSent = invocation.namedArguments[Symbol('codeSent')] as Function(String, int?);
           codeSent('verification_id', 123);
        });

        await service.sendVerificationCode(
          contact: contact,
          method: TwoFactorMethod.sms,
          onCodeSent: (id) {
            codeSentCalled = true;
            expect(id, 'verification_id');
          },
          onError: (e) => fail('Should not fail'),
        );

        verify(mockAuth.verifyPhoneNumber(
          phoneNumber: contact,
          verificationCompleted: anyNamed('verificationCompleted'),
          verificationFailed: anyNamed('verificationFailed'),
          codeSent: anyNamed('codeSent'),
          codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        )).called(1);

        expect(codeSentCalled, true);
      });

      test('Email: calls Cloud Function', () async {
        final email = 'test@example.com';
        var codeSentCalled = false;

        when(mockFunctions.httpsCallable('sendTwoFactorEmail'))
            .thenReturn(mockCallable);
        when(mockCallable.call({'email': email}))
            .thenAnswer((_) async => mockCallableResult);
        when(mockCallableResult.data)
            .thenReturn({'verificationId': 'email_ver_id'});

        await service.sendVerificationCode(
          contact: email,
          method: TwoFactorMethod.email,
          onCodeSent: (id) {
            codeSentCalled = true;
            expect(id, 'email_ver_id');
          },
          onError: (e) => fail('Should not fail'),
        );

        verify(mockFunctions.httpsCallable('sendTwoFactorEmail')).called(1);
        verify(mockCallable.call({'email': email})).called(1);
        expect(codeSentCalled, true);
      });
    });

    group('verifyCode', () {
      test('SMS: links credential successfully', () async {
        final verId = 'ver_id';
        final code = '123456';

        // We cannot easily mock PhoneAuthProvider.credential as it is static.
        // But we can verify linkWithCredential is called with SOME credential.

        when(mockUser.linkWithCredential(any))
            .thenAnswer((_) async => MockUserCredential());

        final result = await service.verifyCode(
          verificationId: verId,
          code: code,
          method: TwoFactorMethod.sms,
        );

        expect(result, true);
        verify(mockUser.linkWithCredential(any)).called(1);
      });

      test('SMS: reauthenticates if already linked', () async {
        final verId = 'ver_id';
        final code = '123456';

        // First link fails
        when(mockUser.linkWithCredential(any))
            .thenThrow(FirebaseAuthException(code: 'provider-already-linked'));

        // Re-auth succeeds
        when(mockUser.reauthenticateWithCredential(any))
            .thenAnswer((_) async => MockUserCredential());

        final result = await service.verifyCode(
          verificationId: verId,
          code: code,
          method: TwoFactorMethod.sms,
        );

        expect(result, true);
        verify(mockUser.linkWithCredential(any)).called(1);
        verify(mockUser.reauthenticateWithCredential(any)).called(1);
      });

      test('Email: calls verify Cloud Function', () async {
        final verId = 'ver_id';
        final code = '123456';

        when(mockFunctions.httpsCallable('verifyTwoFactorEmail'))
            .thenReturn(mockCallable);
        when(mockCallable.call({'verificationId': verId, 'code': code}))
            .thenAnswer((_) async => mockCallableResult);
        when(mockCallableResult.data).thenReturn({'success': true});

        final result = await service.verifyCode(
          verificationId: verId,
          code: code,
          method: TwoFactorMethod.email,
        );

        expect(result, true);
        verify(mockFunctions.httpsCallable('verifyTwoFactorEmail')).called(1);
      });
    });

    group('Firestore Updates', () {
      test('enableTwoFactor updates user document', () async {
        final userId = 'user_123';
        await fakeFirestore.collection('users').doc(userId).set({});

        await service.enableTwoFactor(userId, TwoFactorMethod.sms, '+123');

        final doc = await fakeFirestore.collection('users').doc(userId).get();
        expect(doc.data()!['isTwoFactorEnabled'], true);
        expect(doc.data()!['twoFactorMethod'], 'sms');
        expect(doc.data()!['phoneNumber'], '+123');
      });

      test('disableTwoFactor updates user document', () async {
        final userId = 'user_123';
        await fakeFirestore.collection('users').doc(userId).set({
          'isTwoFactorEnabled': true
        });

        await service.disableTwoFactor(userId);

        final doc = await fakeFirestore.collection('users').doc(userId).get();
        expect(doc.data()!['isTwoFactorEnabled'], false);
      });
    });
  });
}

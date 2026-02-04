import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/services/two_factor_auth_service.dart';

// Import the generated mocks
import 'two_factor_auth_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFunctions,
  HttpsCallable,
  HttpsCallableResult,
  FirebaseFirestore,
  FirebaseAuth,
  User,
  CollectionReference,
  DocumentReference
])
void main() {
  late TwoFactorAuthService service;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult mockResult;
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDoc;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockResult = MockHttpsCallableResult();
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();

    service = TwoFactorAuthService(
      functions: mockFunctions,
      firestore: mockFirestore,
      auth: mockAuth,
    );
  });

  group('TwoFactorAuthService', () {
    test('sendVerificationCode calls sendTwoFactorCode cloud function', () async {
      // Arrange
      when(mockFunctions.httpsCallable('sendTwoFactorCode'))
          .thenReturn(mockCallable);
      when(mockCallable.call(any))
          .thenAnswer((_) async => mockResult);
      when(mockResult.data).thenReturn({'success': true, 'message': 'Sent'});

      // Act
      await service.sendVerificationCode(method: TwoFactorMethod.email);

      // Assert
      verify(mockFunctions.httpsCallable('sendTwoFactorCode')).called(1);
      verify(mockCallable.call({'method': 'email'})).called(1);
    });

    test('verifyCode calls verifyTwoFactorCode cloud function and returns true when valid', () async {
      // Arrange
      when(mockFunctions.httpsCallable('verifyTwoFactorCode'))
          .thenReturn(mockCallable);
      when(mockCallable.call(any))
          .thenAnswer((_) async => mockResult);
      when(mockResult.data).thenReturn({'valid': true});

      // Act
      final result = await service.verifyCode(code: '123456');

      // Assert
      expect(result, true);
      verify(mockFunctions.httpsCallable('verifyTwoFactorCode')).called(1);
      verify(mockCallable.call({'code': '123456'})).called(1);
    });

    test('verifyCode returns false when invalid', () async {
      // Arrange
      when(mockFunctions.httpsCallable('verifyTwoFactorCode'))
          .thenReturn(mockCallable);
      when(mockCallable.call(any))
          .thenAnswer((_) async => mockResult);
      when(mockResult.data).thenReturn({'valid': false});

      // Act
      final result = await service.verifyCode(code: '123456');

      // Assert
      expect(result, false);
    });

    test('enableTwoFactor updates firestore', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_uid');
      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc('test_uid')).thenReturn(mockDoc);
      when(mockDoc.update(any)).thenAnswer((_) async => {});

      await service.enableTwoFactor();

      verify(mockDoc.update({'isTwoFactorEnabled': true})).called(1);
    });

    test('disableTwoFactor updates firestore', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_uid');
      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc('test_uid')).thenReturn(mockDoc);
      when(mockDoc.update(any)).thenAnswer((_) async => {});

      await service.disableTwoFactor();

      verify(mockDoc.update({'isTwoFactorEnabled': false})).called(1);
    });
  });
}

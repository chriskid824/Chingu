import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chingu/utils/encryption_helper.dart';

@GenerateMocks([FlutterSecureStorage])
import 'encryption_helper_test.mocks.dart';

void main() {
  late EncryptionHelper encryptionHelper;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    encryptionHelper = EncryptionHelper();
    encryptionHelper.storage = mockStorage;
    encryptionHelper.reset(); // Reset state
  });

  group('EncryptionHelper Tests', () {
    test('init() generates and saves new key if not exists', () async {
      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => null);

      await encryptionHelper.init();

      verify(mockStorage.read(key: 'encryption_key')).called(1);
      verify(mockStorage.write(key: 'encryption_key', value: anyNamed('value'))).called(1);
    });

    test('init() loads existing key', () async {
      // Valid 32-byte (256-bit) key in Base64
      const validKeyBase64 = 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=';

      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => validKeyBase64);

      await encryptionHelper.init();

      verify(mockStorage.read(key: 'encryption_key')).called(1);
      verifyNever(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')));
    });

    test('encrypt and decrypt round trip work', () async {
      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => null);

      await encryptionHelper.init();

      const plainText = 'Hello, World!';
      final encrypted = encryptionHelper.encryptData(plainText);

      expect(encrypted, isNot(plainText));
      expect(encrypted.contains(':'), isTrue);

      final decrypted = encryptionHelper.decryptData(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('encrypt throws if not initialized', () {
      expect(() => encryptionHelper.encryptData('test'), throwsException);
    });

    test('decrypt throws if format invalid', () async {
       when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);
       when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => null);

       await encryptionHelper.init();

       expect(() => encryptionHelper.decryptData('invalid_data'), throwsException);
    });
  });
}

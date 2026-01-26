import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chingu/utils/encryption_helper.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

@GenerateNiceMocks([MockSpec<FlutterSecureStorage>()])
import 'encryption_helper_test.mocks.dart';

void main() {
  late EncryptionHelper encryptionHelper;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    encryptionHelper = EncryptionHelper();
    encryptionHelper.storage = mockStorage;
    encryptionHelper.reset();
  });

  group('EncryptionHelper', () {
    test('init generates and saves new key if not present', () async {
      // Arrange
      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);

      // Act
      await encryptionHelper.init();

      // Assert
      verify(mockStorage.read(key: 'app_encryption_key')).called(1);
      verify(mockStorage.write(key: 'app_encryption_key', value: anyNamed('value'))).called(1);
      expect(encryptionHelper.isInitialized, true);
    });

    test('init uses existing key if present', () async {
      // Arrange
      // Generate a valid 32-byte key base64
      final validKey = encrypt.Key.fromSecureRandom(32).base64;

      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => validKey);

      // Act
      await encryptionHelper.init();

      // Assert
      verify(mockStorage.read(key: 'app_encryption_key')).called(1);
      verifyNever(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')));
      expect(encryptionHelper.isInitialized, true);
    });

    test('encryptData and decryptData work correctly', () async {
      // Arrange
      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null); // Let it generate a key

      await encryptionHelper.init();

      const plainText = 'Sensitive Chat Message';

      // Act
      final encrypted = encryptionHelper.encryptData(plainText);

      // Assert
      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted, contains(':')); // Check format iv:data

      final decrypted = encryptionHelper.decryptData(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('encryptData produces different outputs for same input (IV randomization)', () async {
      // Arrange
      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);

      await encryptionHelper.init();

      const plainText = 'Same Message';

      // Act
      final encrypted1 = encryptionHelper.encryptData(plainText);
      final encrypted2 = encryptionHelper.encryptData(plainText);

      // Assert
      expect(encrypted1, isNot(equals(encrypted2)));

      // Both should decrypt to same
      expect(encryptionHelper.decryptData(encrypted1), equals(plainText));
      expect(encryptionHelper.decryptData(encrypted2), equals(plainText));
    });

    test('decryptData throws FormatException on invalid format', () async {
      await encryptionHelper.init();
      expect(() => encryptionHelper.decryptData('invalid_base64'), throwsA(isA<FormatException>()));
    });

    test('methods throw StateError if not initialized', () {
      expect(() => encryptionHelper.encryptData('test'), throwsStateError);
      expect(() => encryptionHelper.decryptData('test'), throwsStateError);
    });
  });
}

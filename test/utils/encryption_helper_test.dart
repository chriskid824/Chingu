import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    late EncryptionHelper encryptionHelper;
    // 32-byte key for AES-256
    // "12345678901234567890123456789012"
    const String validKey = '12345678901234567890123456789012';

    setUp(() {
      encryptionHelper = EncryptionHelper(validKey);
    });

    test('should encrypt and decrypt data correctly', () {
      const plainText = 'Hello, World!';
      final encrypted = encryptionHelper.encryptData(plainText);

      expect(encrypted, isNot(plainText));
      expect(encrypted.contains(':'), isTrue);

      final decrypted = encryptionHelper.decryptData(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('should produce different ciphertexts for same plaintext (IV randomization)', () {
      const plainText = 'Sensitive Data';
      final encrypted1 = encryptionHelper.encryptData(plainText);
      final encrypted2 = encryptionHelper.encryptData(plainText);

      expect(encrypted1, isNot(equals(encrypted2)));

      final decrypted1 = encryptionHelper.decryptData(encrypted1);
      final decrypted2 = encryptionHelper.decryptData(encrypted2);

      expect(decrypted1, equals(plainText));
      expect(decrypted2, equals(plainText));
    });

    test('should throw ArgumentError for invalid key length', () {
      expect(() => EncryptionHelper('short_key'), throwsArgumentError);
    });

    test('should work with generated base64 key', () {
      final key = EncryptionHelper.generateRandomKey();
      final helper = EncryptionHelper.fromBase64(key);

      const plainText = 'Test Data';
      final encrypted = helper.encryptData(plainText);
      final decrypted = helper.decryptData(encrypted);

      expect(decrypted, equals(plainText));
    });

    test('should throw FormatException for invalid encrypted format', () {
      expect(() => encryptionHelper.decryptData('invalid_format'), throwsFormatException);
    });
  });
}

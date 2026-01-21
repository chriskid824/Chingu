import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    const validKey = 'mysecretkey123456789012345678901'; // 32 chars
    const shortKey = 'shortkey';
    const plainText = 'Hello, World!';

    test('should encrypt and decrypt correctly with valid key', () {
      final encrypted = EncryptionHelper.encrypt(plainText, validKey);
      expect(encrypted, isNot(equals(plainText)));

      final decrypted = EncryptionHelper.decrypt(encrypted, validKey);
      expect(decrypted, equals(plainText));
    });

    test('should encrypt and decrypt correctly with short key (padding logic)', () {
      final encrypted = EncryptionHelper.encrypt(plainText, shortKey);
      expect(encrypted, isNot(equals(plainText)));

      final decrypted = EncryptionHelper.decrypt(encrypted, shortKey);
      expect(decrypted, equals(plainText));
    });

    test('should produce different ciphertexts for same input (random IV)', () {
      final encrypted1 = EncryptionHelper.encrypt(plainText, validKey);
      final encrypted2 = EncryptionHelper.encrypt(plainText, validKey);

      expect(encrypted1, isNot(equals(encrypted2)));

      final decrypted1 = EncryptionHelper.decrypt(encrypted1, validKey);
      final decrypted2 = EncryptionHelper.decrypt(encrypted2, validKey);

      expect(decrypted1, equals(plainText));
      expect(decrypted2, equals(plainText));
    });

    test('should fail to decrypt with wrong key', () {
      final encrypted = EncryptionHelper.encrypt(plainText, validKey);
      const wrongKey = 'wrongkey123456789012345678901234';

      // AES decryption with wrong key usually results in garbage or padding error.
      // Encrypt package might throw or return garbage.
      // With PKCS7 padding, it's likely to throw an error about invalid padding.
      expect(
        () => EncryptionHelper.decrypt(encrypted, wrongKey),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw ArgumentError for empty key', () {
      expect(
        () => EncryptionHelper.encrypt(plainText, ''),
        throwsArgumentError,
      );
      expect(
        () => EncryptionHelper.decrypt('someencryptedtext', ''),
        throwsArgumentError,
      );
    });

    test('should throw ArgumentError for invalid encrypted text (too short)', () {
      expect(
        () => EncryptionHelper.decrypt('short', validKey),
        throwsA(isA<Exception>()), // Could be FormatException (base64) or ArgumentError
      );
    });
  });
}

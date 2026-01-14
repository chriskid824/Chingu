import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper Tests', () {
    const String secretKey = 'my_secret_password';
    const String plainText = 'This is a sensitive chat message.';

    test('encrypt should return a string in "iv:ciphertext" format', () {
      final encrypted = EncryptionHelper.encrypt(plainText, secretKey);

      expect(encrypted, isNotEmpty);
      expect(encrypted.contains(':'), isTrue);

      final parts = encrypted.split(':');
      expect(parts.length, 2);
    });

    test('decrypt should return original text', () {
      final encrypted = EncryptionHelper.encrypt(plainText, secretKey);
      final decrypted = EncryptionHelper.decrypt(encrypted, secretKey);

      expect(decrypted, equals(plainText));
    });

    test('encryption should be randomized (different IVs)', () {
      final encrypted1 = EncryptionHelper.encrypt(plainText, secretKey);
      final encrypted2 = EncryptionHelper.encrypt(plainText, secretKey);

      expect(encrypted1, isNot(equals(encrypted2)));

      // But both should decrypt to same text
      final decrypted1 = EncryptionHelper.decrypt(encrypted1, secretKey);
      final decrypted2 = EncryptionHelper.decrypt(encrypted2, secretKey);

      expect(decrypted1, equals(plainText));
      expect(decrypted2, equals(plainText));
    });

    test('decrypt should fail with wrong key', () {
      final encrypted = EncryptionHelper.encrypt(plainText, secretKey);
      const wrongKey = 'wrong_password';

      // My implementation catches internal errors and rethrows as Exception
      expect(
        () => EncryptionHelper.decrypt(encrypted, wrongKey),
        throwsException,
      );
    });

    test('decrypt should throw on invalid format', () {
      expect(
        () => EncryptionHelper.decrypt('invalid_format_string', secretKey),
        throwsException,
      );
    });
  });
}

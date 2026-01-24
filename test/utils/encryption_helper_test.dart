import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    test('generateKey returns a valid base64 key', () {
      final key = EncryptionHelper.generateKey();
      expect(key, isNotEmpty);
      expect(key, isA<String>());
      // 32 bytes encoded in base64 should be 44 chars
      expect(key.length, equals(44));
    });

    test('encrypt and decrypt round trip works', () {
      final key = EncryptionHelper.generateKey();
      final originalText = 'Hello, World! 123 測試';

      final encrypted = EncryptionHelper.encrypt(originalText, secretKey: key);
      expect(encrypted, isNot(originalText));
      expect(encrypted, isNotEmpty);

      final decrypted = EncryptionHelper.decrypt(encrypted, secretKey: key);
      expect(decrypted, equals(originalText));
    });

    test('encrypt produces different output for same input due to random IV', () {
      final key = EncryptionHelper.generateKey();
      final text = 'Sensitive Data';

      final encrypted1 = EncryptionHelper.encrypt(text, secretKey: key);
      final encrypted2 = EncryptionHelper.encrypt(text, secretKey: key);

      expect(encrypted1, isNot(equals(encrypted2)));

      // Both should still decrypt to the same text
      expect(EncryptionHelper.decrypt(encrypted1, secretKey: key), equals(text));
      expect(EncryptionHelper.decrypt(encrypted2, secretKey: key), equals(text));
    });

    test('decrypt throws error on short data', () {
      final key = EncryptionHelper.generateKey();
      // "SGVsbG8=" is "Hello" in base64, less than 16 bytes when decoded (5 bytes)
      expect(
        () => EncryptionHelper.decrypt("SGVsbG8=", secretKey: key),
        throwsArgumentError,
      );
    });
  });
}

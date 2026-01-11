import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    late EncryptionHelper encryptionHelper;

    setUp(() {
      encryptionHelper = EncryptionHelper();
      // Ensure we start with a fresh state or fallback key
      // Note: EncryptionHelper is a Singleton, so state persists.
      // We can re-init with a known key for testing.
      encryptionHelper.init('test_key_32_chars_long_exactly!!');
    });

    test('encrypts and decrypts correctly', () {
      const plainText = 'Hello, World!';
      final encrypted = encryptionHelper.encrypt(plainText);

      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted.contains(':'), isTrue);

      final decrypted = encryptionHelper.decrypt(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('decrypt returns original text if format is invalid', () {
      const invalidText = 'not_encrypted_text';
      final decrypted = encryptionHelper.decrypt(invalidText);
      expect(decrypted, equals(invalidText));
    });

    test('handles empty string', () {
      const plainText = '';
      final encrypted = encryptionHelper.encrypt(plainText);
      final decrypted = encryptionHelper.decrypt(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('different IVs produce different ciphertexts for same input', () {
      const plainText = 'Same Text';
      final encrypted1 = encryptionHelper.encrypt(plainText);
      final encrypted2 = encryptionHelper.encrypt(plainText);

      expect(encrypted1, isNot(equals(encrypted2)));

      final decrypted1 = encryptionHelper.decrypt(encrypted1);
      final decrypted2 = encryptionHelper.decrypt(encrypted2);

      expect(decrypted1, equals(plainText));
      expect(decrypted2, equals(plainText));
    });
  });
}

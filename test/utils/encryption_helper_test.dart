import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper Tests', () {
    test('generateKey should return a 32-character string', () {
      final key = EncryptionHelper.generateKey();
      expect(key.length, 32);
    });

    test('Should encrypt and decrypt correctly', () {
      final plainText = 'Hello World';
      final key = EncryptionHelper.generateKey();

      final encrypted = EncryptionHelper.encrypt(plainText, key);
      expect(encrypted, isNot(plainText));
      expect(encrypted, contains(':')); // Contains IV separator

      final decrypted = EncryptionHelper.decrypt(encrypted, key);
      expect(decrypted, plainText);
    });

    test('Should handle custom short keys (padding)', () {
      final plainText = 'Secret Data';
      final shortKey = 'short';

      final encrypted = EncryptionHelper.encrypt(plainText, shortKey);
      final decrypted = EncryptionHelper.decrypt(encrypted, shortKey);
      expect(decrypted, plainText);
    });

    test('Should handle custom long keys (truncation)', () {
      final plainText = 'Secret Data';
      final longKey = 'this_key_is_very_very_long_and_exceeds_32_bytes_surely';

      final encrypted = EncryptionHelper.encrypt(plainText, longKey);
      final decrypted = EncryptionHelper.decrypt(encrypted, longKey);
      expect(decrypted, plainText);
    });

    test('Should fail to decrypt with wrong key', () {
      final plainText = 'Sensitive';
      final key1 = EncryptionHelper.generateKey();
      final key2 = EncryptionHelper.generateKey();

      final encrypted = EncryptionHelper.encrypt(plainText, key1);

      // Decrypting with wrong key usually fails due to padding check
      try {
        EncryptionHelper.decrypt(encrypted, key2);
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e.toString(), contains('Decryption failed'));
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    late String key;
    late EncryptionHelper helper;

    setUp(() {
      key = EncryptionHelper.generateRandomKey();
      helper = EncryptionHelper(base64Key: key);
    });

    test('should encrypt and decrypt string correctly', () {
      const plainText = 'This is a secret message';
      final encrypted = helper.encryptData(plainText);

      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted.contains(':'), isTrue); // Check for separator

      final decrypted = helper.decryptData(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('should produce different ciphertexts for same plaintext due to random IV', () {
      const plainText = 'Same message';
      final encrypted1 = helper.encryptData(plainText);
      final encrypted2 = helper.encryptData(plainText);

      expect(encrypted1, isNot(equals(encrypted2)));

      expect(helper.decryptData(encrypted1), equals(plainText));
      expect(helper.decryptData(encrypted2), equals(plainText));
    });

    test('should throw exception on invalid format', () {
      expect(() => helper.decryptData('invalid_format'), throwsException);
    });

    test('should handle empty string', () {
      const plainText = '';
      final encrypted = helper.encryptData(plainText);
      final decrypted = helper.decryptData(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('should handle unicode characters', () {
      const plainText = '👋 Hello 世界';
      final encrypted = helper.encryptData(plainText);
      final decrypted = helper.decryptData(encrypted);
      expect(decrypted, equals(plainText));
    });
  });
}

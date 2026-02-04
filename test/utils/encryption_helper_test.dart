import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    const keyString = '12345678901234567890123456789012'; // 32 chars

    test('should throw ArgumentError if key is not 32 chars', () {
      expect(() => EncryptionHelper('shortkey'), throwsArgumentError);
    });

    test('should encrypt and decrypt correctly', () {
      final helper = EncryptionHelper(keyString);
      const plainText = 'Hello World';

      final encrypted = helper.encryptData(plainText);
      expect(encrypted, isNot(plainText));
      expect(encrypted, contains(':'));

      final decrypted = helper.decryptData(encrypted);
      expect(decrypted, plainText);
    });

    test('should produce different ciphertexts for same plaintext due to random IV', () {
      final helper = EncryptionHelper(keyString);
      const plainText = 'Hello World';

      final encrypted1 = helper.encryptData(plainText);
      final encrypted2 = helper.encryptData(plainText);

      expect(encrypted1, isNot(encrypted2));

      // Both should decrypt to same text
      expect(helper.decryptData(encrypted1), plainText);
      expect(helper.decryptData(encrypted2), plainText);
    });

    test('should throw FormatException for invalid format', () {
      final helper = EncryptionHelper(keyString);
      expect(() => helper.decryptData('invalid_string'), throwsFormatException);
    });
  });
}

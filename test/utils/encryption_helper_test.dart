import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    const testKey = '12345678901234567890123456789012'; // 32 chars

    test('should throw error if not initialized', () {
      expect(() => EncryptionHelper.encryptData('test'), throwsStateError);
      expect(() => EncryptionHelper.decryptData('test'), throwsStateError);
    });

    test('should throw error if key length is invalid', () {
      expect(() => EncryptionHelper.init('short'), throwsArgumentError);
    });

    test('should encrypt and decrypt correctly', () {
      EncryptionHelper.init(testKey);
      const originalText = 'Hello, World!';

      final encrypted = EncryptionHelper.encryptData(originalText);
      expect(encrypted, isNot(originalText));
      expect(encrypted, contains(':')); // Check format

      final decrypted = EncryptionHelper.decryptData(encrypted);
      expect(decrypted, equals(originalText));
    });

    test('should generate different encrypted text for same input (different IV)', () {
      EncryptionHelper.init(testKey);
      const text = 'Sensitive Data';

      final encrypted1 = EncryptionHelper.encryptData(text);
      final encrypted2 = EncryptionHelper.encryptData(text);

      expect(encrypted1, isNot(equals(encrypted2)));

      // But both should decrypt to same text
      expect(EncryptionHelper.decryptData(encrypted1), equals(text));
      expect(EncryptionHelper.decryptData(encrypted2), equals(text));
    });

    test('should throw error on invalid encrypted format', () {
      EncryptionHelper.init(testKey);
      expect(() => EncryptionHelper.decryptData('invalid_format'), throwsArgumentError);
    });
  });
}

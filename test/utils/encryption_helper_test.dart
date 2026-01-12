import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    late EncryptionHelper encryptionHelper;
    const testKey = '12345678901234567890123456789012'; // 32 chars
    const plainText = 'Hello, World! This is a secret message.';

    setUp(() {
      encryptionHelper = EncryptionHelper();
      // Reset the singleton state if possible or just re-init
      // Since it's a singleton, we should test behaviors carefully.
      // We will initialize it for the tests.
      encryptionHelper.init(testKey);
    });

    test('should encrypt and decrypt correctly', () {
      final encrypted = encryptionHelper.encryptData(plainText);

      expect(encrypted, isNotEmpty);
      expect(encrypted.contains(':'), isTrue);

      final parts = encrypted.split(':');
      expect(parts.length, 2);

      final decrypted = encryptionHelper.decryptData(encrypted);
      expect(decrypted, plainText);
    });

    test('should return empty string when input is empty', () {
      expect(encryptionHelper.encryptData(''), '');
      expect(encryptionHelper.decryptData(''), '');
    });

    test('should throw ArgumentError if key is not 32 chars', () {
      expect(() => encryptionHelper.init('short_key'), throwsArgumentError);
    });

    test('should throw FormatException if encrypted format is invalid', () {
      expect(() => encryptionHelper.decryptData('invalid_base64_string'), throwsFormatException);
    });

    test('should produce different ciphertexts for same plaintext due to random IV', () {
      final encrypted1 = encryptionHelper.encryptData(plainText);
      final encrypted2 = encryptionHelper.encryptData(plainText);

      expect(encrypted1, isNot(equals(encrypted2)));

      // But both should decrypt to same text
      expect(encryptionHelper.decryptData(encrypted1), plainText);
      expect(encryptionHelper.decryptData(encrypted2), plainText);
    });
  });
}

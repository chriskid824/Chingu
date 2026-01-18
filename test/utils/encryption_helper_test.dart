import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    late EncryptionHelper encryptionHelper;
    // 32 chars for AES-256
    const String testKey = '12345678901234567890123456789012';
    const String plainText = 'This is a secret message';

    setUp(() {
      encryptionHelper = EncryptionHelper();
    });

    test('should encrypt and decrypt correctly', () {
      final encrypted = encryptionHelper.encrypt(plainText, testKey);

      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted.contains(':'), true); // Check for separator

      final decrypted = encryptionHelper.decrypt(encrypted, testKey);
      expect(decrypted, equals(plainText));
    });

    test('should generate different outputs for same input due to random IV', () {
      final encrypted1 = encryptionHelper.encrypt(plainText, testKey);
      final encrypted2 = encryptionHelper.encrypt(plainText, testKey);

      expect(encrypted1, isNot(equals(encrypted2)));

      // Both should decrypt to the same text
      expect(encryptionHelper.decrypt(encrypted1, testKey), equals(plainText));
      expect(encryptionHelper.decrypt(encrypted2, testKey), equals(plainText));
    });

    test('should throw error for invalid format', () {
      expect(
        () => encryptionHelper.decrypt('invalid_format', testKey),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

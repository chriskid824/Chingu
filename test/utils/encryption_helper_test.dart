import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    const key = 'my_super_secret_key_32_chars_long';

    late EncryptionHelper helper;

    setUp(() {
      helper = EncryptionHelper(key);
    });

    test('should encrypt and decrypt correctly', () {
      const plainText = 'Hello, World!';
      final encrypted = helper.encrypt(plainText);

      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted, contains(':')); // Contains IV separator

      final decrypted = helper.decrypt(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('should produce different ciphertexts for same plaintext due to random IV', () {
      const plainText = 'Sensitive Data';
      final encrypted1 = helper.encrypt(plainText);
      final encrypted2 = helper.encrypt(plainText);

      expect(encrypted1, isNot(equals(encrypted2)));

      // But both should decrypt to same text
      expect(helper.decrypt(encrypted1), equals(plainText));
      expect(helper.decrypt(encrypted2), equals(plainText));
    });

    test('should handle short keys by padding', () {
      final shortKeyHelper = EncryptionHelper('short');
      const plainText = 'Test';
      final encrypted = shortKeyHelper.encrypt(plainText);
      expect(shortKeyHelper.decrypt(encrypted), equals(plainText));
    });

    test('should handle long keys by truncation', () {
      final longKeyHelper = EncryptionHelper('a' * 50);
      const plainText = 'Test';
      final encrypted = longKeyHelper.encrypt(plainText);
      expect(longKeyHelper.decrypt(encrypted), equals(plainText));
    });

    test('should throw FormatException for invalid encrypted format', () {
      expect(() => helper.decrypt('invalid_format'), throwsA(isA<FormatException>()));
    });
  });
}

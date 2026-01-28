import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    const String passphrase = 'my_secret_passphrase';
    late EncryptionHelper helper;

    setUp(() {
      helper = EncryptionHelper(passphrase);
    });

    test('should encrypt and decrypt correctly', () {
      const String originalText = 'This is a secret message';

      final encrypted = helper.encrypt(originalText);
      expect(encrypted, isNot(equals(originalText)));
      expect(encrypted.contains(':'), isTrue);

      final decrypted = helper.decrypt(encrypted);
      expect(decrypted, equals(originalText));
    });

    test('should generate different ciphertexts for same input (Random IV)', () {
      const String originalText = 'Same message';

      final encrypted1 = helper.encrypt(originalText);
      final encrypted2 = helper.encrypt(originalText);

      expect(encrypted1, isNot(equals(encrypted2)));

      // Both should decrypt to the same original text
      expect(helper.decrypt(encrypted1), equals(originalText));
      expect(helper.decrypt(encrypted2), equals(originalText));
    });

    test('should throw FormatException for invalid format', () {
      expect(() => helper.decrypt('invalid_format'), throwsA(isA<FormatException>()));
    });

    test('should fail to decrypt with wrong key', () {
        final helper2 = EncryptionHelper('wrong_passphrase');
        final encrypted = helper.encrypt('Secret data');

        // Decrypting with wrong key usually throws an error due to padding check failure
        // It throws ArgumentError (which is an Error, not Exception) in pointycastle
        expect(() => helper2.decrypt(encrypted), throwsA(anything));
    });

    test('should handle empty string', () {
        final encrypted = helper.encrypt('');
        expect(encrypted, isEmpty);
        expect(helper.decrypt(encrypted), isEmpty);
    });

    test('should handle unicode characters', () {
        const text = '你好，世界！👋';
        final encrypted = helper.encrypt(text);
        expect(helper.decrypt(encrypted), equals(text));
    });
  });
}

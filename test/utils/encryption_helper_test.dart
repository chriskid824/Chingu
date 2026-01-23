import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    // 32 characters key
    const validKey = '12345678901234567890123456789012';

    test('should throw error if key is not 32 characters', () {
      expect(() => EncryptionHelper('shortkey'), throwsArgumentError);
    });

    test('should encrypt and decrypt correctly', () {
      final helper = EncryptionHelper(validKey);
      const plainText = 'This is a secret message';

      final encrypted = helper.encrypt(plainText);
      expect(encrypted, isNot(plainText));
      expect(encrypted, isNotEmpty);

      final decrypted = helper.decrypt(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('should produce different ciphertexts for same plaintext (random IV)', () {
      final helper = EncryptionHelper(validKey);
      const plainText = 'Same message';

      final encrypted1 = helper.encrypt(plainText);
      final encrypted2 = helper.encrypt(plainText);

      expect(encrypted1, isNot(equals(encrypted2)));

      // But both should decrypt to same
      expect(helper.decrypt(encrypted1), equals(plainText));
      expect(helper.decrypt(encrypted2), equals(plainText));
    });

    test('should throw error when decrypting invalid data', () {
      final helper = EncryptionHelper(validKey);
      expect(() => helper.decrypt('invalid_base64'), throwsException);
    });

     test('should throw error when decrypting with wrong key', () {
      final helper1 = EncryptionHelper(validKey);
      final helper2 = EncryptionHelper('a2345678901234567890123456789012'); // slightly different

      const plainText = 'Secret';
      final encrypted = helper1.encrypt(plainText);

      // Decrypting with wrong key usually produces garbage or throws padding error
      // because of PKCS7 padding check failing
      expect(() => helper2.decrypt(encrypted), throwsException);
    });
  });
}

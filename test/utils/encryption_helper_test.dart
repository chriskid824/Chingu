import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    late String key;
    late EncryptionHelper helper;

    setUp(() {
      key = EncryptionHelper.generateKey();
      helper = EncryptionHelper(key);
    });

    test('should encrypt and decrypt correctly', () {
      const plainText = 'Sensitive Chat Log Data';
      final encrypted = helper.encryptData(plainText);

      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted.contains(':'), isTrue);

      final decrypted = helper.decryptData(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('should produce different ciphertexts for same plaintext (Random IV)', () {
      const plainText = 'Same Text';
      final encrypted1 = helper.encryptData(plainText);
      final encrypted2 = helper.encryptData(plainText);

      expect(encrypted1, isNot(equals(encrypted2)));

      expect(helper.decryptData(encrypted1), equals(plainText));
      expect(helper.decryptData(encrypted2), equals(plainText));
    });

    test('should fail to decrypt with wrong key', () {
      const plainText = 'Secret';
      final encrypted = helper.encryptData(plainText);

      final wrongKey = EncryptionHelper.generateKey();
      final wrongHelper = EncryptionHelper(wrongKey);

      // AES decryption with wrong key usually produces garbage, which causes padding error
      expect(() => wrongHelper.decryptData(encrypted), throwsA(anything));
    });

    test('should throw FormatException for invalid format', () {
      expect(() => helper.decryptData('invalid_format'), throwsA(isA<FormatException>()));
    });
  });
}

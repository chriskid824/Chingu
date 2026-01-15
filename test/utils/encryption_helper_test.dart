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
      const plainText = 'Hello World';
      final encrypted = helper.encrypt(plainText);

      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted, contains(':')); // Check format

      final decrypted = helper.decrypt(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('should generate different ciphertexts for same plaintext (IV randomization)', () {
      const plainText = 'Hello World';
      final encrypted1 = helper.encrypt(plainText);
      final encrypted2 = helper.encrypt(plainText);

      expect(encrypted1, isNot(equals(encrypted2)));

      final decrypted1 = helper.decrypt(encrypted1);
      final decrypted2 = helper.decrypt(encrypted2);

      expect(decrypted1, equals(plainText));
      expect(decrypted2, equals(plainText));
    });

    test('should throw FormatException for invalid format', () {
      expect(() => helper.decrypt('invalid_format'), throwsA(isA<FormatException>()));
    });
  });
}

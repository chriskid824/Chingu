import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    late String keyString;
    late EncryptionHelper helper;

    setUp(() {
      keyString = EncryptionHelper.generateKey();
      helper = EncryptionHelper(keyString);
    });

    test('generateKey returns a valid key', () {
      final key = EncryptionHelper.generateKey();
      expect(key, isNotEmpty);
      expect(key, isA<String>());
      // Base64 encoded 32 bytes should be approx 44 chars
      expect(key.length, greaterThan(30));
    });

    test('encrypt returns a string in correct format', () {
      final plainText = 'Hello World';
      final encrypted = helper.encrypt(plainText);

      expect(encrypted, contains(':'));
      final parts = encrypted.split(':');
      expect(parts.length, 2);
    });

    test('decrypt restores original text', () {
      final plainText = 'Sensitive Data 123';
      final encrypted = helper.encrypt(plainText);
      final decrypted = helper.decrypt(encrypted);

      expect(decrypted, equals(plainText));
    });

    test('encrypt produces different outputs for same text (Random IV)', () {
      final plainText = 'Same Text';
      final encrypted1 = helper.encrypt(plainText);
      final encrypted2 = helper.encrypt(plainText);

      expect(encrypted1, isNot(equals(encrypted2)));

      // But both should decrypt to the same text
      expect(helper.decrypt(encrypted1), equals(plainText));
      expect(helper.decrypt(encrypted2), equals(plainText));
    });

    test('decrypt throws exception on invalid format', () {
      expect(() => helper.decrypt('invalid_format'), throwsException);
    });

    test('decrypt works with UTF-8 characters', () {
      final plainText = '你好，世界！Chat logs 📝';
      final encrypted = helper.encrypt(plainText);
      final decrypted = helper.decrypt(encrypted);

      expect(decrypted, equals(plainText));
    });
  });
}

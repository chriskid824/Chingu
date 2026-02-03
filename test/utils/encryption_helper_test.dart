import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    const plainText = 'Hello, this is a secret message!';
    const secretKey = 'my_super_secret_key_123456789012'; // 32 chars
    const shortKey = 'short_key';

    test('應該能夠加密數據', () {
      final encrypted = EncryptionHelper.encrypt(plainText, secretKey);

      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted, contains(':')); // 確保包含分隔符

      final parts = encrypted.split(':');
      expect(parts.length, equals(2)); // IV 和 密文
    });

    test('應該能夠解密數據還原原始文本', () {
      final encrypted = EncryptionHelper.encrypt(plainText, secretKey);
      final decrypted = EncryptionHelper.decrypt(encrypted, secretKey);

      expect(decrypted, equals(plainText));
    });

    test('應該能夠處理短密鑰 (自動補全)', () {
      final encrypted = EncryptionHelper.encrypt(plainText, shortKey);
      final decrypted = EncryptionHelper.decrypt(encrypted, shortKey);

      expect(decrypted, equals(plainText));
    });

    test('每次加密應該產生不同的結果 (因為隨機 IV)', () {
      final encrypted1 = EncryptionHelper.encrypt(plainText, secretKey);
      final encrypted2 = EncryptionHelper.encrypt(plainText, secretKey);

      expect(encrypted1, isNot(equals(encrypted2)));

      // 但兩者都應該能解密
      expect(EncryptionHelper.decrypt(encrypted1, secretKey), equals(plainText));
      expect(EncryptionHelper.decrypt(encrypted2, secretKey), equals(plainText));
    });

    test('使用錯誤的密鑰解密應該失敗或產生亂碼', () {
      final encrypted = EncryptionHelper.encrypt(plainText, secretKey);
      final wrongKey = 'wrong_key_should_fail___________';

      // AES-SIC 模式下，錯誤密鑰通常會產生亂碼，而不是拋出異常
      // 除非剛好格式錯誤。我們驗證它不等於原始文本即可。
      try {
        final decrypted = EncryptionHelper.decrypt(encrypted, wrongKey);
        expect(decrypted, isNot(equals(plainText)));
      } catch (e) {
        // 如果拋出異常也是可接受的結果 (視具體 AES 模式而定)
        expect(true, isTrue);
      }
    });

    test('解密格式錯誤的數據應該拋出異常', () {
      expect(
        () => EncryptionHelper.decrypt('invalid_format_string', secretKey),
        throwsException,
      );
    });
  });
}

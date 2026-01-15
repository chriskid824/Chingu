import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  final Key key;
  late final Encrypter _encrypter;

  EncryptionHelper(String keyBase64) : key = Key.fromBase64(keyBase64) {
    _encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  }

  String encrypt(String plainText) {
    final iv = IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    // Return iv + ciphertext encoded together
    return '${iv.base64}:${encrypted.base64}';
  }

  String decrypt(String encryptedText) {
    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid encrypted text format');
    }
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    return _encrypter.decrypt(encrypted, iv: iv);
  }

  static String generateKey() {
    return Key.fromSecureRandom(32).base64;
  }
}

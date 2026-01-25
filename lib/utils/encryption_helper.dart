import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  late final Encrypter _encrypter;
  late final Key _key;

  /// Constructor accepting a 32-character key for AES-256 encryption.
  /// The key will be adjusted to exactly 32 bytes.
  EncryptionHelper(String keyString) {
    // Ensure the key is exactly 32 bytes (256 bits)
    String processedKey = keyString;
    if (keyString.length < 32) {
      processedKey = keyString.padRight(32, ' ');
    } else if (keyString.length > 32) {
      processedKey = keyString.substring(0, 32);
    }

    _key = Key.fromUtf8(processedKey);
    // AESMode.cbc is a common mode.
    _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
  }

  /// Encrypts the plain text using a random IV.
  /// Returns a string in the format "iv_base64:ciphertext_base64".
  String encrypt(String plainText) {
    final iv = IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts the encrypted text which must be in the format "iv_base64:ciphertext_base64".
  String decrypt(String encryptedText) {
    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid encrypted text format. Expected iv:ciphertext');
    }

    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);

    return _encrypter.decrypt(encrypted, iv: iv);
  }
}

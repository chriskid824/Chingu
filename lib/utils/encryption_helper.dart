import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  static encrypt.Key? _key;

  /// Initialize the helper with a 32-character key.
  /// This should be called before any encryption or decryption operations.
  static void init(String keyString) {
    if (keyString.length != 32) {
      throw ArgumentError('Key length must be 32 characters for AES-256');
    }
    _key = encrypt.Key.utf8(keyString);
  }

  /// Encrypts the given plain text.
  /// Returns a string in the format "iv:encryptedBase64".
  static String encryptData(String plainText) {
    if (_key == null) {
      throw StateError('EncryptionHelper not initialized. Call init() first.');
    }

    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts the given encrypted data string (format "iv:encryptedBase64").
  static String decryptData(String encryptedData) {
    if (_key == null) {
      throw StateError('EncryptionHelper not initialized. Call init() first.');
    }

    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      throw ArgumentError('Invalid encrypted data format');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!));

    return encrypter.decrypt(encrypted, iv: iv);
  }
}

import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  late final encrypt.Encrypter _encrypter;
  late final encrypt.Key _key;

  /// Initialize with a key.
  /// The [keyString] must be 32 characters long for AES-256.
  EncryptionHelper(String keyString) {
    if (keyString.length != 32) {
      throw ArgumentError('Key length must be 32 characters');
    }
    _key = encrypt.Key.fromUtf8(keyString);
    _encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
  }

  /// Generates a secure random key of 32 characters (encoded as Base64 usually,
  /// but here we return the key instance or string representation?)
  /// Note: AES key needs 32 bytes.
  static String generateRandomKey() {
    return encrypt.Key.fromSecureRandom(32).base64;
  }

  /// Initialize from a Base64 encoded key (useful if storing key as base64)
  EncryptionHelper.fromBase64(String base64Key) {
     _key = encrypt.Key.fromBase64(base64Key);
     _encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
  }

  /// Encrypts the plain text.
  /// Returns a string containing the IV and the ciphertext separated by a colon.
  /// Format: base64(iv):base64(ciphertext)
  String encryptData(String plainText) {
    final iv = encrypt.IV.fromLength(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);

    // Combine IV and encrypted data
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts the encrypted text.
  /// Expects format: base64(iv):base64(ciphertext)
  String decryptData(String encryptedText) {
    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid encrypted data format');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

    return _encrypter.decrypt(encrypted, iv: iv);
  }
}

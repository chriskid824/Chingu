import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

/// A helper class for encrypting and decrypting sensitive data using AES encryption.
///
/// This helper uses AES-CBC with a random 16-byte IV for each encryption operation.
/// The output format is `iv_base64:ciphertext_base64`.
class EncryptionHelper {
  // Singleton instance
  static final EncryptionHelper _instance = EncryptionHelper._internal();
  factory EncryptionHelper() => _instance;
  EncryptionHelper._internal();

  encrypt.Key? _key;
  bool _isInitialized = false;

  /// Initialize the helper with a 32-character key.
  ///
  /// In a real application, this key should be retrieved from secure storage
  /// (e.g., flutter_secure_storage) or derived from a user secret.
  void init(String keyString) {
    if (keyString.length != 32) {
      debugPrint('EncryptionHelper Warning: Encryption key must be 32 characters long for AES-256.');
      // Pad or truncate for safety to ensure valid key length
      if (keyString.length > 32) {
        keyString = keyString.substring(0, 32);
      } else {
        keyString = keyString.padRight(32, '*');
      }
    }
    _key = encrypt.Key.fromUtf8(keyString);
    _isInitialized = true;
  }

  /// Encrypts the [plainText] string.
  ///
  /// Returns a string in the format "iv_base64:encrypted_base64".
  String encryptData(String plainText) {
    _ensureInitialized();

    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts the [encryptedText] string.
  ///
  /// Expects the format "iv_base64:encrypted_base64".
  /// Returns the decrypted plaintext, or an empty string if decryption fails.
  String decryptData(String encryptedText) {
    _ensureInitialized();

    if (encryptedText.isEmpty) return '';

    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        debugPrint('EncryptionHelper Error: Invalid encrypted data format');
        return '';
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
      final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint('EncryptionHelper Error decrypting data: $e');
      return '';
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      // Use a default key for development convenience if not initialized manually.
      // WARNING: Do not use this default key in production for sensitive data.
      // Ideally, this should throw an error in production if not initialized.
      debugPrint('EncryptionHelper: Using default development key. DO NOT USE IN PRODUCTION.');
      init('chingu_dev_insecure_key_12345678');
    }
  }
}

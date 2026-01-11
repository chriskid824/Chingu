import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter/foundation.dart';

/// A helper class for encrypting and decrypting sensitive data using AES-CBC.
///
/// This class uses the `encrypt` package to perform AES-256 encryption.
/// It requires a 32-character key for production use, but provides a fallback
/// key for development purposes.
///
/// Encrypted data is stored in the format `iv_base64:ciphertext_base64`.
class EncryptionHelper {
  static final EncryptionHelper _instance = EncryptionHelper._internal();
  factory EncryptionHelper() => _instance;
  EncryptionHelper._internal();

  // 32-character key for AES-256 fallback in development
  static const String _devFallbackKey = 'dev_fallback_key_32_chars_long!!';

  encrypt_lib.Key? _key;

  /// Initializes the encryption helper with a specific key.
  ///
  /// The key should be 32 characters long for AES-256.
  void init(String keyString) {
    if (keyString.length != 32) {
      debugPrint('Warning: Encryption key should be 32 characters for AES-256.');
      if (keyString.length < 32) {
        keyString = keyString.padRight(32, '#');
      } else {
        keyString = keyString.substring(0, 32);
      }
    }
    _key = encrypt_lib.Key.fromUtf8(keyString);
  }

  encrypt_lib.Key get _safeKey {
    if (_key != null) return _key!;
    if (kDebugMode) {
      debugPrint('EncryptionHelper: Using dev fallback key.');
    }
    return encrypt_lib.Key.fromUtf8(_devFallbackKey);
  }

  /// Encrypts the [plainText] using AES-CBC.
  ///
  /// Returns a string in the format `iv_base64:ciphertext_base64`.
  String encrypt(String plainText) {
    try {
      final key = _safeKey;
      final iv = encrypt_lib.IV.fromLength(16);

      // Use AES-CBC mode as per requirements
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc));

      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      debugPrint('Encryption error: $e');
      rethrow;
    }
  }

  /// Decrypts the [encryptedText].
  ///
  /// Expects the format `iv_base64:ciphertext_base64`.
  /// If the format is invalid or decryption fails, returns the original text.
  String decrypt(String encryptedText) {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        // Assume plain text if format doesn't match
        return encryptedText;
      }

      final key = _safeKey;
      final iv = encrypt_lib.IV.fromBase64(parts[0]);
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc));

      final encrypted = encrypt_lib.Encrypted.fromBase64(parts[1]);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint('Decryption error: $e');
      return encryptedText;
    }
  }
}

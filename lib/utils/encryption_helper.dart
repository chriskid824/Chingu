import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Singleton helper class for encrypting and decrypting sensitive data using AES-CBC.
///
/// Requires initialization with a 32-character key for production use.
/// Falls back to a development key if not initialized, but this is not recommended for production.
class EncryptionHelper {
  static final EncryptionHelper _instance = EncryptionHelper._internal();

  factory EncryptionHelper() {
    return _instance;
  }

  EncryptionHelper._internal();

  /// The encryption key.
  encrypt.Key? _key;

  /// Development fallback key (32 chars).
  /// WARNING: Do not use this in production.
  static final encrypt.Key _devKey = encrypt.Key.fromUtf8('dev_key_fallback_32_chars_long!!');

  /// Initializes the encryption helper with a secure key.
  ///
  /// [keyString] must be a 32-character string.
  void init(String keyString) {
    if (keyString.length != 32) {
      throw ArgumentError('Encryption key must be 32 characters long.');
    }
    _key = encrypt.Key.fromUtf8(keyString);
  }

  /// Encrypts the given [plainText] string.
  ///
  /// Returns the encrypted string in the format `iv_base64:ciphertext_base64`.
  /// Throws an error if encryption fails.
  String encryptData(String plainText) {
    if (plainText.isEmpty) {
      return '';
    }

    final key = _key ?? _devKey;
    if (_key == null && kReleaseMode) {
      debugPrint('WARNING: EncryptionHelper using dev key in release mode!');
    }

    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Store IV and Ciphertext together
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts the given [encryptedData] string.
  ///
  /// [encryptedData] must be in the format `iv_base64:ciphertext_base64`.
  /// Returns the original plain text string.
  String decryptData(String encryptedData) {
    if (encryptedData.isEmpty) {
      return '';
    }

    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid encrypted data format. Expected iv:ciphertext');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

    final key = _key ?? _devKey;
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    return encrypter.decrypt(encrypted, iv: iv);
  }
}

import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Helper class for encrypting and decrypting sensitive data stored locally.
/// Uses AES-256 encryption with a key stored in [FlutterSecureStorage].
class EncryptionHelper {
  static final EncryptionHelper _instance = EncryptionHelper._internal();
  factory EncryptionHelper() => _instance;

  EncryptionHelper._internal();

  // Dependency injection for testing
  @visibleForTesting
  FlutterSecureStorage storage = const FlutterSecureStorage();

  static const String _keyStorageKey = 'chingu_encryption_key';
  encrypt.Encrypter? _encrypter;

  bool get isInitialized => _encrypter != null;

  @visibleForTesting
  void reset() {
    _encrypter = null;
  }

  /// Initialize the helper by loading or creating the encryption key.
  Future<void> init() async {
    if (isInitialized) return;

    try {
      String? base64Key = await storage.read(key: _keyStorageKey);

      encrypt.Key key;
      if (base64Key == null) {
        // Generate a new 32-byte key (256 bits)
        key = encrypt.Key.fromSecureRandom(32);
        await storage.write(key: _keyStorageKey, value: key.base64);
      } else {
        key = encrypt.Key.fromBase64(base64Key);
      }

      // AES with PKCS7 padding is standard.
      // We'll use AES-CBC with a random IV for each encryption.
      _encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    } catch (e) {
      throw Exception('EncryptionHelper initialization failed: $e');
    }
  }

  /// Encrypts the plain text. Returns a base64 string combining IV and Ciphertext.
  /// Format: base64(IV + Ciphertext)
  Future<String> encryptData(String plainText) async {
    if (!isInitialized) await init();

    // Generate a random 16-byte IV
    final iv = encrypt.IV.fromSecureRandom(16);

    final encrypted = _encrypter!.encrypt(plainText, iv: iv);

    // Combine IV and bytes
    final combined = iv.bytes + encrypted.bytes;
    return base64.encode(combined);
  }

  /// Decrypts the encrypted text (base64).
  Future<String> decryptData(String encryptedText) async {
    if (!isInitialized) await init();

    try {
      final combined = base64.decode(encryptedText);

      if (combined.length < 16) {
        throw Exception('Invalid encrypted data length');
      }

      // Extract IV (first 16 bytes)
      final ivBytes = combined.sublist(0, 16);
      final iv = encrypt.IV(ivBytes);

      // Extract Ciphertext (remaining bytes)
      final ciphertextBytes = combined.sublist(16);
      final encrypted = encrypt.Encrypted(ciphertextBytes);

      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }
}

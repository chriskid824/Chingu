import 'dart:async';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class EncryptionHelper {
  // Singleton instance
  static final EncryptionHelper _instance = EncryptionHelper._internal();

  factory EncryptionHelper() {
    return _instance;
  }

  EncryptionHelper._internal();

  static const String _keyStorageKey = 'secure_encryption_key';
  FlutterSecureStorage _storage = const FlutterSecureStorage();

  encrypt.Key? _key;
  bool _isInitialized = false;
  Future<void>? _initFuture;

  /// Allows injecting a mock storage for testing purposes.
  @visibleForTesting
  void setStorage(FlutterSecureStorage storage) {
    _storage = storage;
    // Reset initialization state if storage is swapped (e.g., in tests)
    _isInitialized = false;
    _key = null;
    _initFuture = null;
  }

  /// Initializes the encryption helper by loading or generating the key.
  Future<void> init() async {
    if (_isInitialized && _key != null) return;

    // Prevent concurrent initialization calls
    if (_initFuture != null) {
      return _initFuture;
    }

    _initFuture = _initLogic();
    return _initFuture;
  }

  Future<void> _initLogic() async {
    try {
      String? keyString = await _storage.read(key: _keyStorageKey);

      if (keyString == null) {
        // Generate a new 32-byte (256-bit) key
        final key = encrypt.Key.fromSecureRandom(32);
        keyString = key.base64;
        await _storage.write(key: _keyStorageKey, value: keyString);
      }

      _key = encrypt.Key.fromBase64(keyString);
      _isInitialized = true;
    } catch (e) {
      // If initialization fails, reset the future so it can be retried
      _initFuture = null;
      rethrow;
    }
  }

  /// Encrypts the given plain text string.
  /// Returns a format of "iv:ciphertext" (both base64 encoded).
  Future<String> encryptData(String plainText) async {
    if (!_isInitialized) {
      await init();
    }

    // Generate a random IV (Initialization Vector) - 16 bytes for AES
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Combine IV and Ciphertext for storage
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts the given encrypted string (format "iv:ciphertext").
  Future<String> decryptData(String encryptedText) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid encrypted text format');
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);

      final encrypter = encrypt.Encrypter(encrypt.AES(_key!));
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      // Re-throw or handle accordingly. For now, we propagate the error.
      rethrow;
    }
  }
}

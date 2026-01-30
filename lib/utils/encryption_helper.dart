import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Helper class for encrypting and decrypting sensitive data using AES-256.
class EncryptionHelper {
  // Singleton instance
  static final EncryptionHelper _instance = EncryptionHelper._internal();

  factory EncryptionHelper() {
    return _instance;
  }

  EncryptionHelper._internal();

  FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _keyStorageKey = 'encryption_key';

  encrypt.Encrypter? _encrypter;
  bool _isInitialized = false;

  /// Allows injecting a mock storage for testing.
  @visibleForTesting
  set storage(FlutterSecureStorage storage) {
    _storage = storage;
  }

  /// Initializes the encryption helper by loading or generating the key.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      String? keyBase64 = await _storage.read(key: _keyStorageKey);

      encrypt.Key key;
      if (keyBase64 == null) {
        // Generate a new 32-byte (256-bit) key
        key = encrypt.Key.fromSecureRandom(32);
        await _storage.write(key: _keyStorageKey, value: key.base64);
      } else {
        key = encrypt.Key.fromBase64(keyBase64);
      }

      // Initialize Encrypter with AES algorithm
      _encrypter = encrypt.Encrypter(encrypt.AES(key));
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize EncryptionHelper: $e');
    }
  }

  /// Encrypts the plain text string.
  /// Returns a string in format "iv_base64:ciphertext_base64".
  String encryptData(String plainText) {
    _checkInitialized();

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter!.encrypt(plainText, iv: iv);

    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts the encrypted data string (format "iv_base64:ciphertext_base64").
  String decryptData(String encryptedData) {
    _checkInitialized();

    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid encrypted data format');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

    return _encrypter!.decrypt(encrypted, iv: iv);
  }

  void _checkInitialized() {
    if (!_isInitialized || _encrypter == null) {
      throw Exception('EncryptionHelper not initialized. Call init() first.');
    }
  }

  /// Reset for testing
  @visibleForTesting
  void reset() {
    _isInitialized = false;
    _encrypter = null;
  }
}

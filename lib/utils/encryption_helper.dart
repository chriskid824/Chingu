import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Helper class for encrypting and decrypting sensitive local data.
/// Uses AES encryption with a securely stored key.
class EncryptionHelper {
  // Singleton instance
  static final EncryptionHelper _instance = EncryptionHelper._internal();

  factory EncryptionHelper() => _instance;

  EncryptionHelper._internal();

  encrypt.Encrypter? _encrypter;

  // Storage key for the encryption key
  static const String _keyStorageKey = 'app_encryption_key';

  // Dependencies
  FlutterSecureStorage? _storage;

  // Dependency injection for testing
  @visibleForTesting
  set storage(FlutterSecureStorage storage) => _storage = storage;

  FlutterSecureStorage get _secureStorage =>
      _storage ?? const FlutterSecureStorage();

  /// Initialize the encryption helper.
  /// Checks if an encryption key exists in secure storage.
  /// If not, generates a new one and saves it.
  /// Then initializes the AES encrypter.
  Future<void> init() async {
    if (_encrypter != null) return;

    try {
      String? keyBase64 = await _secureStorage.read(key: _keyStorageKey);

      encrypt.Key key;
      if (keyBase64 == null) {
        // Generate a new 32-byte (256-bit) key
        key = encrypt.Key.fromSecureRandom(32);
        await _secureStorage.write(key: _keyStorageKey, value: key.base64);
      } else {
        key = encrypt.Key.fromBase64(keyBase64);
      }

      // Initialize AES encrypter
      // Using AES in SIC (Stream Integer Counter) mode (default in this package)
      _encrypter = encrypt.Encrypter(encrypt.AES(key));
    } catch (e) {
      debugPrint('Error initializing EncryptionHelper: $e');
      rethrow;
    }
  }

  /// Encrypts a plain text string.
  /// Returns a string in format "iv_base64:encrypted_base64".
  String encryptData(String plainText) {
    if (_encrypter == null) {
      throw StateError('EncryptionHelper must be initialized calling init()');
    }

    try {
      // Generate a random IV (Initialization Vector) for each encryption
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypted = _encrypter!.encrypt(plainText, iv: iv);

      // Combine IV and encrypted data with a separator
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      debugPrint('Encryption error: $e');
      rethrow;
    }
  }

  /// Decrypts an encrypted string in format "iv_base64:encrypted_base64".
  String decryptData(String encryptedText) {
    if (_encrypter == null) {
      throw StateError('EncryptionHelper must be initialized calling init()');
    }

    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw const FormatException('Invalid encrypted text format');
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint('Decryption error: $e');
      rethrow;
    }
  }

  /// Helper to check if helper is initialized
  bool get isInitialized => _encrypter != null;

  /// Reset for testing
  @visibleForTesting
  void reset() {
    _encrypter = null;
  }
}

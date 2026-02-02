import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' hide Key;

/// Helper class for encrypting and decrypting sensitive data locally.
/// Uses AES encryption with a securely stored key.
class EncryptionHelper {
  static final EncryptionHelper _instance = EncryptionHelper._internal();
  factory EncryptionHelper() => _instance;

  EncryptionHelper._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _keyStorageKey = 'local_encryption_key';

  // Cache the key in memory after loading
  Key? _key;
  Future<void>? _initFuture;

  // Allow dependency injection for testing
  @visibleForTesting
  FlutterSecureStorage? storageOverride;

  @visibleForTesting
  void resetForTesting() {
    _key = null;
    _initFuture = null;
  }

  FlutterSecureStorage get storage => storageOverride ?? _storage;

  /// Ensures the encryption key is loaded from secure storage or generated if it doesn't exist.
  Future<void> _ensureKey() {
    if (_key != null) return Future.value();
    _initFuture ??= _initializeKey();
    return _initFuture!;
  }

  Future<void> _initializeKey() async {
    String? keyString = await storage.read(key: _keyStorageKey);

    if (keyString == null) {
      // Generate a new 32-byte (256-bit) key
      final newKey = Key.fromSecureRandom(32);
      await storage.write(key: _keyStorageKey, value: newKey.base64);
      _key = newKey;
    } else {
      _key = Key.fromBase64(keyString);
    }
  }

  /// Encrypts the given plain text string.
  /// Returns a string containing the IV and the encrypted data, separated by a colon.
  /// Format: base64(iv):base64(encrypted)
  Future<String> encrypt(String plainText) async {
    await _ensureKey();

    // Generate a random IV (Initialization Vector) for each encryption
    final iv = IV.fromSecureRandom(16);

    // Use AES in CBC mode
    final encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Combine IV and Encrypted data to store them together
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts the given encrypted string.
  /// Expects the format: base64(iv):base64(encrypted)
  Future<String> decrypt(String encryptedText) async {
    await _ensureKey();

    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid encrypted text format');
    }

    final iv = IV.fromBase64(parts[0]);
    final encryptedData = Encrypted.fromBase64(parts[1]);

    final encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));

    return encrypter.decrypt(encryptedData, iv: iv);
  }
}

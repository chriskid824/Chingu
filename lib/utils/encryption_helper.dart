import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Helper class for encrypting and decrypting sensitive data using AES encryption.
///
/// It uses [FlutterSecureStorage] to securely store the encryption key.
class EncryptionHelper {
  static EncryptionHelper? _instance;

  factory EncryptionHelper() {
    _instance ??= EncryptionHelper._internal();
    return _instance!;
  }

  EncryptionHelper._internal();

  FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Allows injecting a mock storage for testing purposes.
  @visibleForTesting
  void setStorage(FlutterSecureStorage storage) {
    _storage = storage;
    // Reset initialization state if storage changes
    _isInitialized = false;
    _key = null;
  }

  final String _keyStorageKey = 'app_encryption_key';

  Key? _key;
  bool _isInitialized = false;

  /// Initialize the helper by loading or creating the encryption key.
  Future<void> init() async {
    if (_isInitialized && _key != null) return;

    String? keyString = await _storage.read(key: _keyStorageKey);

    if (keyString == null) {
      // Generate a new 32-byte key (256 bits)
      final key = Key.fromSecureRandom(32);
      await _storage.write(key: _keyStorageKey, value: key.base64);
      _key = key;
    } else {
      _key = Key.fromBase64(keyString);
    }
    _isInitialized = true;
  }

  /// Encrypts the plain text and returns a base64 encoded string containing both IV and ciphertext.
  ///
  /// Format: Base64(IV + Ciphertext)
  Future<String> encryptData(String plainText) async {
    if (!_isInitialized) await init();

    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Combine IV and Encrypted bytes
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);

    return base64.encode(combined);
  }

  /// Decrypts the base64 encoded string.
  ///
  /// Expects format: Base64(IV + Ciphertext)
  Future<String> decryptData(String encryptedData) async {
    if (!_isInitialized) await init();

    try {
      final combined = base64.decode(encryptedData);

      // Extract IV (first 16 bytes)
      if (combined.length < 16) {
        throw Exception('Invalid encrypted data length');
      }

      final ivBytes = combined.sublist(0, 16);
      final iv = IV(ivBytes);

      // Extract Ciphertext
      final cipherBytes = combined.sublist(16);
      final encrypted = Encrypted(cipherBytes);

      final encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }
}

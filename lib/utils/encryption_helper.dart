import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

/// A helper class for encrypting and decrypting sensitive data using AES.
class EncryptionHelper {
  // AES block size is 128 bit = 16 bytes
  static const int _ivLength = 16;

  /// Encrypts the [plainText] using the provided [keyString].
  ///
  /// [keyString] should be 32 characters long for AES-256.
  /// Returns a Base64 encoded string containing both the IV and the encrypted data.
  static String encrypt(String plainText, String keyString) {
    if (keyString.isEmpty) {
      throw ArgumentError('Key must not be empty');
    }

    // Ensure key is 32 bytes (256 bits) for AES-256.
    // If shorter/longer, we should probably hash it or pad it.
    // For this helper, we'll use Key.utf8 but users should ensure correct length for best security.
    // Alternatively, we could pad it here.
    final key = Key.utf8(keyString.padRight(32, '0').substring(0, 32));

    final iv = IV.fromSecureRandom(_ivLength);
    final encrypter = Encrypter(AES(key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Combine IV and encrypted bytes
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);

    return base64.encode(combined);
  }

  /// Decrypts the [encryptedText] using the provided [keyString].
  ///
  /// Returns the original plain text.
  /// Throws [ArgumentError] if the format is invalid.
  static String decrypt(String encryptedText, String keyString) {
    if (keyString.isEmpty) {
      throw ArgumentError('Key must not be empty');
    }

    final key = Key.utf8(keyString.padRight(32, '0').substring(0, 32));
    final encrypter = Encrypter(AES(key));

    try {
      final decoded = base64.decode(encryptedText);

      if (decoded.length < _ivLength) {
        throw ArgumentError('Invalid encrypted text format: too short');
      }

      final ivBytes = decoded.sublist(0, _ivLength);
      final contentBytes = decoded.sublist(_ivLength);

      final iv = IV(ivBytes);
      final encrypted = Encrypted(contentBytes);

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      if (e is ArgumentError) rethrow;
      throw FormatException('Failed to decrypt data: $e');
    }
  }
}

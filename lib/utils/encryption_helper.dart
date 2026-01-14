import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// Utility class for encrypting and decrypting sensitive data using AES.
class EncryptionHelper {
  /// Encrypts the given plain text using the provided secret key.
  ///
  /// The [plainText] is encrypted using AES-CBC with a randomly generated IV.
  /// The [secretKey] is hashed using SHA-256 to ensure it is 32 bytes (256 bits).
  ///
  /// Returns a string in the format "iv:encryptedText" (both base64 encoded).
  static String encrypt(String plainText, String secretKey) {
    try {
      final key = _createKey(secretKey);
      final iv = encrypt.IV.fromLength(16); // Generate random 16-byte IV
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Return IV and Encrypted text separated by colon
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypts the given encrypted text using the provided secret key.
  ///
  /// The [encryptedText] must be in the format "iv:ciphertext".
  /// The [secretKey] is hashed using SHA-256 to derive the decryption key.
  ///
  /// Returns the original plain text.
  static String decrypt(String encryptedText, String secretKey) {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted text format');
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
      final key = _createKey(secretKey);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Helper to create a 32-byte Key from a string using SHA-256 hashing.
  static encrypt.Key _createKey(String keyString) {
    final bytes = utf8.encode(keyString);
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }
}

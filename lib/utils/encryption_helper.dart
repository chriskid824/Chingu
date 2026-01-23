import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;

/// A utility class for encrypting and decrypting sensitive data using AES.
///
/// Usage:
/// ```dart
/// final helper = EncryptionHelper('your-32-char-secret-key-here!!');
/// final encrypted = helper.encrypt('sensitive data');
/// final decrypted = helper.decrypt(encrypted);
/// ```
class EncryptionHelper {
  final encrypt_pkg.Key _key;
  final encrypt_pkg.AESMode _mode = encrypt_pkg.AESMode.cbc;
  final String _padding = 'PKCS7';

  /// Creates an instance of [EncryptionHelper] with the given [keyString].
  ///
  /// [keyString] must be 32 characters long for AES-256.
  EncryptionHelper(String keyString)
      : _key = encrypt_pkg.Key.fromUtf8(keyString) {
    if (keyString.length != 32) {
      throw ArgumentError('Key length must be 32 characters.');
    }
  }

  /// Encrypts the [plainText] using AES-CBC.
  ///
  /// Returns a Base64 encoded string containing the IV and the encrypted data.
  /// The format is: Base64(IV + EncryptedBytes).
  String encrypt(String plainText) {
    final iv = encrypt_pkg.IV.fromLength(16); // Generate random 16-byte IV
    final encrypter = encrypt_pkg.Encrypter(
      encrypt_pkg.AES(
        _key,
        mode: _mode,
        padding: _padding
      )
    );

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Combine IV and encrypted bytes
    final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);

    return base64.encode(combined);
  }

  /// Decrypts the [encryptedText] which must be in the format returned by [encrypt].
  String decrypt(String encryptedText) {
    try {
      final decoded = base64.decode(encryptedText);

      if (decoded.length < 16) {
        throw Exception('Invalid encrypted data length');
      }

      // Extract IV (first 16 bytes)
      final ivBytes = decoded.sublist(0, 16);
      final iv = encrypt_pkg.IV(ivBytes);

      // Extract encrypted data (rest of the bytes)
      final encryptedBytes = decoded.sublist(16);
      final encrypted = encrypt_pkg.Encrypted(encryptedBytes);

      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(
          _key,
          mode: _mode,
          padding: _padding
        )
      );

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }
}

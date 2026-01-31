import 'package:encrypt/encrypt.dart';

/// A helper class for encrypting and decrypting sensitive data using AES-CBC.
class EncryptionHelper {
  final Key _key;

  /// Creates an [EncryptionHelper] with the given [keyString].
  /// The [keyString] should be a base64 encoded string representing a 32-byte key.
  EncryptionHelper(String keyString) : _key = Key.fromBase64(keyString);

  /// Generates a secure random 32-byte key and returns it as a base64 string.
  static String generateKey() {
    return Key.fromSecureRandom(32).base64;
  }

  /// Encrypts the [plainText] and returns a combined string of IV and ciphertext.
  /// The format is "iv:ciphertext" (both base64 encoded).
  String encrypt(String plainText) {
    // Generate a random IV for each encryption operation
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts the [encryptedText] (format "iv:ciphertext").
  /// Returns the original plain text.
  String decrypt(String encryptedText) {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid encrypted text format. Expected "iv:ciphertext"');
      }

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);

      final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }
}

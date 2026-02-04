import 'package:encrypt/encrypt.dart' as encrypt;

/// A helper class for encrypting and decrypting sensitive data using AES.
class EncryptionHelper {
  final encrypt.Key _key;
  late final encrypt.Encrypter _encrypter;

  /// Creates an instance of [EncryptionHelper].
  ///
  /// [keyString] must be 32 characters long to ensure AES-256 security.
  EncryptionHelper(String keyString) : _key = encrypt.Key.fromUtf8(keyString) {
    if (keyString.length != 32) {
      throw ArgumentError('Key length must be 32 characters for AES-256.');
    }
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  /// Encrypts the [plainText] using AES.
  ///
  /// Generates a random IV for each encryption operation.
  /// Returns a string in the format "iv:ciphertext", where both are Base64 encoded.
  String encryptData(String plainText) {
    final iv = encrypt.IV.fromLength(16); // Generate random IV
    final encrypted = _encrypter.encrypt(plainText, iv: iv);

    // Combine IV and ciphertext, separated by a colon
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts the [encryptedText].
  ///
  /// Expects the input to be in the format "iv:ciphertext" (Base64 encoded).
  /// Throws [FormatException] if the format is invalid.
  String decryptData(String encryptedText) {
    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid encrypted text format. Expected "iv:ciphertext".');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

    return _encrypter.decrypt(encrypted, iv: iv);
  }
}

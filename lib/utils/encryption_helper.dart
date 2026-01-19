import 'package:encrypt/encrypt.dart' as encrypt;

/// A helper class for encrypting and decrypting sensitive data using AES.
class EncryptionHelper {
  final encrypt.Key _key;
  late final encrypt.Encrypter _encrypter;

  /// Creates an [EncryptionHelper] instance with the provided [base64Key].
  /// The key must be a valid Base64 encoded string representing a 32-byte (256-bit) key.
  EncryptionHelper(String base64Key) : _key = encrypt.Key.fromBase64(base64Key) {
    // using AES-CBC (Cipher Block Chaining)
    _encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
  }

  /// Generates a secure random 32-byte (256-bit) key encoded in Base64.
  static String generateKey() {
    return encrypt.Key.fromSecureRandom(32).base64;
  }

  /// Encrypts the [plainText] and returns the encrypted string.
  /// The format of the returned string is "iv:ciphertext" where both are Base64 encoded.
  /// A new random IV is generated for each encryption to ensure semantic security.
  String encryptData(String plainText) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts the [encryptedText] (formatted as "iv:ciphertext") and returns the plain text.
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

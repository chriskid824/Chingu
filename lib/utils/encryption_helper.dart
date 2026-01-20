import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  late final Key _key;
  late final Encrypter _encrypter;

  /// Initializes the helper with a Base64 encoded key.
  /// The key must be 32 bytes (256 bits) for AES-256.
  EncryptionHelper({required String base64Key}) {
    _key = Key.fromBase64(base64Key);
    // Using AES with SIC (Counter) mode by default
    _encrypter = Encrypter(AES(_key));
  }

  /// Encrypts the [plainText] and returns a formatted string containing
  /// the IV and the encrypted data, separated by a colon.
  /// Format: "IV_BASE64:ENCRYPTED_BASE64"
  String encryptData(String plainText) {
    final iv = IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts the [encryptedText] which must follow the format
  /// "IV_BASE64:ENCRYPTED_BASE64".
  String decryptData(String encryptedText) {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid encrypted text format');
      }
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Generates a secure random 32-byte key and returns it as a Base64 string.
  static String generateRandomKey() {
    return Key.fromSecureRandom(32).base64;
  }
}

import 'package:encrypt/encrypt.dart' as encrypt;

/// Encryption Helper Class
///
/// Provides methods to encrypt and decrypt sensitive data using AES.
class EncryptionHelper {
  static final EncryptionHelper _instance = EncryptionHelper._internal();

  factory EncryptionHelper() => _instance;

  EncryptionHelper._internal();

  /// Encrypts a plain text string using the provided key.
  ///
  /// [plainText] The text to encrypt.
  /// [keyString] The secret key (must be 32 characters for AES-256).
  ///
  /// Returns the encrypted string in Base64 format with the IV appended (separated by :).
  String encrypt(String plainText, String keyString) {
    final key = encrypt.Key.utf8(keyString);
    final iv = encrypt.IV.fromLength(16); // Generate random IV
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Return "IV:EncryptedData" so we can extract IV for decryption
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts an encrypted string using the provided key.
  ///
  /// [encryptedText] The encrypted string (format "IV:EncryptedData").
  /// [keyString] The secret key used for encryption.
  ///
  /// Returns the original plain text.
  String decrypt(String encryptedText, String keyString) {
    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid encrypted text format. Expected "IV:EncryptedData"');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);
    final key = encrypt.Key.utf8(keyString);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return encrypter.decrypt(encryptedData, iv: iv);
  }
}

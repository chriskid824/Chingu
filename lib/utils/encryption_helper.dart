import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

/// Helper class for encrypting and decrypting sensitive data using AES.
class EncryptionHelper {
  /// Generates a secure random 32-byte key and returns it as a Base64 string.
  /// This key should be stored securely (e.g., using flutter_secure_storage).
  static String generateKey() {
    final key = Key.fromSecureRandom(32);
    return key.base64;
  }

  /// Encrypts plain text using AES-CBC with a random IV.
  ///
  /// [plainText] The text to encrypt.
  /// [secretKey] A Base64 encoded 32-byte key.
  ///
  /// Returns a Base64 string containing the IV and the ciphertext.
  static String encrypt(String plainText, {required String secretKey}) {
    final key = Key.fromBase64(secretKey);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Combine IV and Ciphertext for storage
    // IV is 16 bytes.
    final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);
    return base64.encode(combined);
  }

  /// Decrypts the encrypted data (Base64 string containing IV + Ciphertext).
  ///
  /// [encryptedData] The Base64 encoded string containing IV and Ciphertext.
  /// [secretKey] A Base64 encoded 32-byte key.
  ///
  /// Returns the original plain text string.
  static String decrypt(String encryptedData, {required String secretKey}) {
    final key = Key.fromBase64(secretKey);
    final decoded = base64.decode(encryptedData);

    if (decoded.length < 16) {
      throw ArgumentError('Invalid encrypted data: too short');
    }

    final ivBytes = decoded.sublist(0, 16);
    final cipherBytes = decoded.sublist(16);

    final iv = IV(ivBytes);
    final encrypted = Encrypted(cipherBytes);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    return encrypter.decrypt(encrypted, iv: iv);
  }
}

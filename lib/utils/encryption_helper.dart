import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;

/// 處理本地數據加密的輔助類
class EncryptionHelper {
  /// 生成隨機的 32 字元金鑰 (256 位元)
  static String generateKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values).substring(0, 32);
  }

  /// 使用 AES 加密數據
  ///
  /// [plainText]: 原始文本
  /// [keyStr]: 金鑰字符串
  ///
  /// 返回格式: "base64(iv):base64(encrypted)"
  static String encrypt(String plainText, String keyStr) {
    try {
      final key = _createKey(keyStr);
      final iv = encrypt_pkg.IV.fromSecureRandom(16);

      final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// 使用 AES 解密數據
  ///
  /// [encryptedText]: 加密後的文本 (格式: "base64(iv):base64(encrypted)")
  /// [keyStr]: 金鑰字符串
  ///
  /// 返回原始文本
  static String decrypt(String encryptedText, String keyStr) {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted format');
      }

      final iv = encrypt_pkg.IV.fromBase64(parts[0]);
      final encrypted = encrypt_pkg.Encrypted.fromBase64(parts[1]);
      final key = _createKey(keyStr);

      final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// 確保金鑰為 32 bytes (256 bits)
  static encrypt_pkg.Key _createKey(String keyStr) {
    List<int> bytes = utf8.encode(keyStr);

    if (bytes.length > 32) {
      bytes = bytes.sublist(0, 32);
    } else if (bytes.length < 32) {
      final newBytes = List<int>.from(bytes);
      while (newBytes.length < 32) {
        newBytes.add(35); // Pad with '#' (ASCII 35) to match previous logic somewhat, or just 0
      }
      bytes = newBytes;
    }

    return encrypt_pkg.Key(Uint8List.fromList(bytes));
  }
}

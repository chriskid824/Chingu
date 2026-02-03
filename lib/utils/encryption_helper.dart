import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

/// 加密輔助類
/// 用於對本地存儲的敏感數據（如聊天記錄）進行加密
class EncryptionHelper {
  /// 加密數據
  ///
  /// [plainText] 原始文本
  /// [secretKey] 密鑰 (可以使用任意長度的字符串，內部會通過 SHA-256 轉換為 32 bytes 密鑰)
  ///
  /// 返回格式: "base64(iv):base64(ciphertext)"
  static String encrypt(String plainText, String secretKey) {
    try {
      final key = _deriveKey(secretKey);
      final iv = IV.fromLength(16); // 生成隨機 IV

      final encrypter = Encrypter(AES(key));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // 拼接 IV 和密文，以便解密時使用
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('加密失敗: $e');
    }
  }

  /// 解密數據
  ///
  /// [encryptedData] 加密後的字符串 (格式: "base64(iv):base64(ciphertext)")
  /// [secretKey] 密鑰 (必須與加密時使用的密鑰相同)
  static String decrypt(String encryptedData, String secretKey) {
    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        throw Exception('無效的加密數據格式');
      }

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      final key = _deriveKey(secretKey);

      final encrypter = Encrypter(AES(key));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('解密失敗: $e');
    }
  }

  /// 使用 SHA-256 從任意字符串導出 32-byte 密鑰
  /// 這樣可以確保即使輸入較短的密碼，也能得到符合 AES-256 要求的密鑰
  static Key _deriveKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return Key(Uint8List.fromList(digest.bytes));
  }
}

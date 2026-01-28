import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

/// 加密輔助類
/// 用於對敏感資料（如聊天記錄）進行本地加密存儲
class EncryptionHelper {
  late final Key _key;

  /// 初始化加密輔助類
  ///
  /// [passphrase] 用於生成加密密鑰的密碼短語。
  /// 會使用 SHA-256 雜湊算法將其轉換為 32 字節的 AES 密鑰。
  EncryptionHelper(String passphrase) {
    final bytes = utf8.encode(passphrase);
    final digest = sha256.convert(bytes);
    _key = Key(Uint8List.fromList(digest.bytes));
  }

  /// 加密文本
  ///
  /// 生成隨機 IV 並使用 AES (CBC 模式) 加密。
  /// 返回格式: "base64(IV):base64(Ciphertext)"
  String encrypt(String plainText) {
    if (plainText.isEmpty) return '';

    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return '${iv.base64}:${encrypted.base64}';
  }

  /// 解密文本
  ///
  /// [encryptedText] 必須是 "base64(IV):base64(Ciphertext)" 格式。
  String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return '';

    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid encrypted text format. Expected "iv:ciphertext"');
    }

    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

    return encrypter.decrypt(encrypted, iv: iv);
  }
}

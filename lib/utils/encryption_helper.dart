import 'package:encrypt/encrypt.dart' as encrypt;

/// 敏感資料加密輔助類
///
/// 使用 AES-CBC 模式進行加密，數據存儲格式為 `iv_base64:ciphertext_base64`。
/// 提供開發環境的預設金鑰，但在生產環境中應透過 [init] 方法顯式初始化。
class EncryptionHelper {
  static final EncryptionHelper _instance = EncryptionHelper._internal();
  static EncryptionHelper get instance => _instance;

  encrypt.Key? _key;

  // 用於開發環境的預設金鑰 (32 bytes for AES-256)
  // 注意：在生產環境中不應依賴此預設值，應從安全存儲或配置中讀取金鑰。
  static final encrypt.Key _fallbackKey = encrypt.Key.fromUtf8('chingu_dev_secret_key_32_bytes!!');

  EncryptionHelper._internal();

  /// 初始化加密輔助類
  ///
  /// [keyString] 必須是 32 個字元的字串或有效的 Base64 編碼字串。
  void init(String keyString) {
    if (keyString.length == 32) {
      _key = encrypt.Key.fromUtf8(keyString);
    } else {
      try {
        _key = encrypt.Key.fromBase64(keyString);
      } catch (e) {
        throw ArgumentError('Invalid key. Key must be 32 characters or a valid Base64 string.');
      }
    }
  }

  /// 加密敏感數據
  ///
  /// [plainText] 明文字串
  /// 回傳格式為 `iv_base64:ciphertext_base64`
  String encryptData(String plainText) {
    if (plainText.isEmpty) return '';

    final key = _key ?? _fallbackKey;
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// 解密敏感數據
  ///
  /// [encryptedText] 格式為 `iv_base64:ciphertext_base64`
  /// 若格式錯誤或解密失敗將拋出異常
  String decryptData(String encryptedText) {
    if (encryptedText.isEmpty) return '';

    final key = _key ?? _fallbackKey;
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid encrypted text format. Expected iv_base64:ciphertext_base64');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

    return encrypter.decrypt(encrypted, iv: iv);
  }
}

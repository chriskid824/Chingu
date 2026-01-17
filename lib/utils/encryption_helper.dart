import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 加密工具類 - 用於對敏感資料（如聊天記錄）進行加密存儲
///
/// 使用 AES-256-CBC 算法。
/// 加密金鑰存儲在 FlutterSecureStorage 中。
class EncryptionHelper {
  static final EncryptionHelper _instance = EncryptionHelper._internal();

  /// 獲取單例實例
  factory EncryptionHelper() => _instance;

  EncryptionHelper._internal();

  /// 可見性僅用於測試：允許注入 storage 和 key
  FlutterSecureStorage storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  Key? _cachedKey;
  Future<Key>? _initKeyFuture;

  static const String _keyStorageKey = 'secure_encryption_key';

  /// 初始化或獲取加密金鑰 (防止並發調用)
  Future<Key> _getKey() {
    if (_cachedKey != null) {
      return Future.value(_cachedKey!);
    }
    _initKeyFuture ??= _loadOrGenerateKey();
    return _initKeyFuture!;
  }

  Future<Key> _loadOrGenerateKey() async {
    // 嘗試從安全存儲中讀取金鑰
    String? keyString = await storage.read(key: _keyStorageKey);

    if (keyString == null) {
      // 如果不存在，生成一個新的 32 字節 (256位) 金鑰
      final key = Key.fromSecureRandom(32);
      // 將金鑰保存到安全存儲
      await storage.write(key: _keyStorageKey, value: base64Url.encode(key.bytes));
      _cachedKey = key;
    } else {
      // 如果存在，解碼並使用
      _cachedKey = Key(base64Url.decode(keyString));
    }

    return _cachedKey!;
  }

  /// 加密字符串
  ///
  /// 返回格式為 "iv_base64:encrypted_content_base64"
  Future<String> encrypt(String plainText) async {
    final key = await _getKey();
    // 為每次加密生成隨機 IV (Initialization Vector)
    final iv = IV.fromSecureRandom(16);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // 返回 IV 和加密內容的組合，以便解密時使用正確的 IV
    return '${iv.base64}:${encrypted.base64}';
  }

  /// 解密字符串
  ///
  /// [encryptedText] 必須是 "iv_base64:encrypted_content_base64" 格式
  Future<String> decrypt(String encryptedText) async {
    final key = await _getKey();

    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw const FormatException('無效的加密文本格式');
    }

    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// 僅用於測試：重置緩存的金鑰和存儲實例
  void resetForTesting() {
    _cachedKey = null;
    _initKeyFuture = null;
    storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
  }
}

import 'dart:async';

/// 訊息翻譯服務
/// 負責將聊天訊息翻譯成用戶的目標語言
class MessageTranslationService {
  static final MessageTranslationService _instance = MessageTranslationService._internal();

  factory MessageTranslationService() {
    return _instance;
  }

  MessageTranslationService._internal();

  /// 模擬翻譯快取
  final Map<String, String> _cache = {};

  /// 翻譯文字
  /// [text] 原始文字
  /// [targetLanguage] 目標語言代碼 (e.g., 'zh_TW', 'en', 'ja')
  /// [sourceLanguage] 來源語言代碼 (可選)
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    if (text.isEmpty) return '';

    final cacheKey = '${text}_$targetLanguage';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // 模擬網絡延遲
    await Future.delayed(const Duration(milliseconds: 300));

    // 在真實實作中，這裡會呼叫 Google Cloud Translation API 或其他翻譯服務
    // 目前使用模擬實作
    String translatedText;

    // 簡單的模擬邏輯
    if (targetLanguage.startsWith('zh')) {
      if (text.toLowerCase().contains('hello')) {
        translatedText = '你好';
      } else if (text.toLowerCase().contains('thank you')) {
        translatedText = '謝謝';
      } else {
        translatedText = '$text (已翻譯)';
      }
    } else if (targetLanguage.startsWith('en')) {
      if (text.contains('你好')) {
        translatedText = 'Hello';
      } else if (text.contains('謝謝')) {
        translatedText = 'Thank you';
      } else {
        translatedText = '$text (Translated)';
      }
    } else {
      translatedText = '$text [$targetLanguage]';
    }

    _cache[cacheKey] = translatedText;
    return translatedText;
  }

  /// 偵測語言 (模擬)
  Future<String> detectLanguage(String text) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // 簡單模擬：包含中文字符視為中文，否則視為英文
    if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(text)) {
      return 'zh_TW';
    }
    return 'en';
  }

  /// 清除快取
  void clearCache() {
    _cache.clear();
  }
}

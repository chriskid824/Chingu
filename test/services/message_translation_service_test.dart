import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/message_translation_service.dart';

void main() {
  group('MessageTranslationService', () {
    late MessageTranslationService service;

    setUp(() {
      service = MessageTranslationService();
      service.clearCache();
    });

    test('translate returns translated text for Chinese target', () async {
      final result = await service.translate(
        text: 'Hello world',
        targetLanguage: 'zh_TW',
      );
      expect(result, contains('你好'));
    });

    test('translate returns translated text for English target', () async {
      final result = await service.translate(
        text: '你好世界',
        targetLanguage: 'en',
      );
      expect(result, contains('Hello'));
    });

    test('translate returns generic format for other languages', () async {
      final result = await service.translate(
        text: 'Hello',
        targetLanguage: 'fr',
      );
      expect(result, 'Hello [fr]');
    });

    test('detectLanguage returns zh_TW for text with Chinese characters', () async {
      final result = await service.detectLanguage('你好世界');
      expect(result, 'zh_TW');
    });

    test('detectLanguage returns en for text without Chinese characters', () async {
      final result = await service.detectLanguage('Hello World');
      expect(result, 'en');
    });

    test('translate uses cache for repeated calls', () async {
      final firstCall = await service.translate(
        text: 'Hello',
        targetLanguage: 'zh_TW',
      );

      final secondCall = await service.translate(
        text: 'Hello',
        targetLanguage: 'zh_TW',
      );

      expect(firstCall, secondCall);
    });
  });
}

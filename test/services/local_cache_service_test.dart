import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chingu/services/local_cache_service.dart';

void main() {
  group('LocalCacheService', () {
    late LocalCacheService localCacheService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      localCacheService = LocalCacheService();
      await localCacheService.init();
    });

    test('should initialize correctly', () {
      expect(localCacheService.isInitialized, true);
    });

    test('should cache and retrieve strings', () async {
      await localCacheService.setString('test_key', 'test_value');
      expect(localCacheService.getString('test_key'), 'test_value');
    });

    test('should cache and retrieve bools', () async {
      await localCacheService.setBool('test_bool', true);
      expect(localCacheService.getBool('test_bool'), true);
    });

    test('should cache and retrieve ints', () async {
      await localCacheService.setInt('test_int', 42);
      expect(localCacheService.getInt('test_int'), 42);
    });

    test('should cache and retrieve user preferences', () async {
      await localCacheService.setThemeMode('dark');
      expect(localCacheService.getThemeMode(), 'dark');

      await localCacheService.setLanguage('zh_TW');
      expect(localCacheService.getLanguage(), 'zh_TW');
    });

    test('should cache and retrieve common data', () async {
      await localCacheService.setOnboardingComplete(true);
      expect(localCacheService.isOnboardingComplete(), true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await localCacheService.setLastLogin(timestamp);
      expect(localCacheService.getLastLogin(), timestamp);

      await localCacheService.setUserId('user_123');
      expect(localCacheService.getUserId(), 'user_123');
    });

    test('should remove values', () async {
      await localCacheService.setString('key_to_remove', 'value');
      expect(localCacheService.getString('key_to_remove'), 'value');

      await localCacheService.remove('key_to_remove');
      expect(localCacheService.getString('key_to_remove'), null);
    });

    test('should clear all values', () async {
      await localCacheService.setString('key1', 'value1');
      await localCacheService.setBool('key2', true);

      await localCacheService.clear();

      expect(localCacheService.getString('key1'), null);
      expect(localCacheService.getBool('key2'), null);
    });
  });
}

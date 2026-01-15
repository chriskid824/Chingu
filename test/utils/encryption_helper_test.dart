import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chingu/utils/encryption_helper.dart';

// Mock implementation of FlutterSecureStorage
class MockSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? wOptions,
    MacOsOptions? mOptions,
    WindowsOptions? winOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? wOptions,
    MacOsOptions? mOptions,
    WindowsOptions? winOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? wOptions,
    MacOsOptions? mOptions,
    WindowsOptions? winOptions,
  }) async {
    _storage.remove(key);
  }
}

void main() {
  group('EncryptionHelper', () {
    late EncryptionHelper helper;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockSecureStorage();
      helper = EncryptionHelper.test(storage: mockStorage);
    });

    test('init generates and saves a new key if none exists', () async {
      // Ensure storage is empty
      expect(await mockStorage.read(key: 'app_encryption_key'), isNull);

      await helper.init();

      // Check if key is saved
      final savedKey = await mockStorage.read(key: 'app_encryption_key');
      expect(savedKey, isNotNull);
      expect(savedKey!.length, greaterThan(0));
    });

    test('init loads existing key', () async {
      // Pre-populate storage with a key (dummy key for testing)
      // Note: EncryptionHelper expects a base64 encoded 32-byte key.
      // 32 bytes = 256 bits.
      // We can generate one or just use a valid string.
      // 32 bytes of 'a' is aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
      // base64 of it.

      // Let's rely on the helper to generate one, save it, then create a new helper to load it.
      await helper.init();
      final key1 = await mockStorage.read(key: 'app_encryption_key');

      // New helper instance with same storage
      final helper2 = EncryptionHelper.test(storage: mockStorage);
      await helper2.init();

      // Should not change the key
      final key2 = await mockStorage.read(key: 'app_encryption_key');
      expect(key1, equals(key2));
    });

    test('encryptData and decryptData work correctly', () async {
      await helper.init();

      const plainText = 'Hello, World! This is a secret message.';

      final encrypted = helper.encryptData(plainText);
      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted, contains(':')); // Check format

      final decrypted = helper.decryptData(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('encryptData produces different outputs for same input (Random IV)', () async {
      await helper.init();

      const plainText = 'Same text';

      final encrypted1 = helper.encryptData(plainText);
      final encrypted2 = helper.encryptData(plainText);

      expect(encrypted1, isNot(equals(encrypted2)));

      // Both should decrypt to same text
      expect(helper.decryptData(encrypted1), equals(plainText));
      expect(helper.decryptData(encrypted2), equals(plainText));
    });

    test('throws StateError if used before init', () {
      expect(() => helper.encryptData('test'), throwsA(isA<StateError>()));
      expect(() => helper.decryptData('test'), throwsA(isA<StateError>()));
    });
  });
}

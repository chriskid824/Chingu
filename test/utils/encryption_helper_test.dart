import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chingu/utils/encryption_helper.dart';

class FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<bool> containsKey({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    return _storage.containsKey(key);
  }

  @override
  Future<void> delete({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    _storage.clear();
  }

  @override
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    return _storage[key];
  }

  @override
  Future<Map<String, String>> readAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    return Map.from(_storage);
  }

  @override
  Future<void> write({required String key, required String? value, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }

  @override
  Future<bool> isCupertinoProtectedDataAvailable() async => true;

  @override
  Stream<bool> get onCupertinoProtectedDataAvailabilityChanged => const Stream.empty();
}

void main() {
  group('EncryptionHelper', () {
    late EncryptionHelper encryptionHelper;
    late FakeSecureStorage fakeStorage;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      encryptionHelper = EncryptionHelper();
      encryptionHelper.resetForTesting();
      encryptionHelper.storage = fakeStorage;
    });

    test('should encrypt and decrypt correctly', () async {
      const plainText = 'Hello World';
      final encrypted = await encryptionHelper.encrypt(plainText);

      expect(encrypted, isNot(plainText));
      expect(encrypted, contains(':')); // Check format

      final decrypted = await encryptionHelper.decrypt(encrypted);
      expect(decrypted, plainText);
    });

    test('should generate and store key if not exists', () async {
      // Ensure storage is empty initially
      expect(await fakeStorage.read(key: 'secure_encryption_key'), isNull);

      await encryptionHelper.encrypt('test');

      // Should have generated and stored a key
      expect(await fakeStorage.read(key: 'secure_encryption_key'), isNotNull);
    });

    test('should reuse existing key', () async {
      // First run to generate key
      await encryptionHelper.encrypt('test1');
      final key1 = await fakeStorage.read(key: 'secure_encryption_key');

      // Reset helper but keep storage (simulating app restart)
      encryptionHelper.resetForTesting();
      encryptionHelper.storage = fakeStorage;

      await encryptionHelper.encrypt('test2');
      final key2 = await fakeStorage.read(key: 'secure_encryption_key');

      expect(key1, key2);
    });

    test('decrypt should throw on invalid format', () async {
      expect(
        () => encryptionHelper.decrypt('invalid_format'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

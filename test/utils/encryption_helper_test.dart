import 'package:chingu/utils/encryption_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
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
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }
}

void main() {
  late EncryptionHelper helper;
  late FakeFlutterSecureStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeFlutterSecureStorage();
    helper = EncryptionHelper();
    helper.resetForTesting();
    helper.storageOverride = fakeStorage;
  });

  test('Should generate key and encrypt/decrypt correctly', () async {
    const originalText = 'Hello World';

    // Encrypt
    final encrypted = await helper.encrypt(originalText);
    expect(encrypted, isNot(originalText));
    expect(encrypted, contains(':')); // Check format

    // Decrypt
    final decrypted = await helper.decrypt(encrypted);
    expect(decrypted, originalText);
  });

  test('Should reuse key from storage', () async {
    const originalText = 'Secret Data';

    // First encryption generates the key
    await helper.encrypt(originalText);

    final key = await fakeStorage.read(key: 'local_encryption_key');
    expect(key, isNotNull);

    // Verify decrypt works with the stored key
    final encrypted = await helper.encrypt(originalText);
    final decrypted = await helper.decrypt(encrypted);
    expect(decrypted, originalText);
  });

  test('Should throw error on invalid format', () async {
    await expectLater(helper.decrypt('invalid_string'), throwsFormatException);
  });
}

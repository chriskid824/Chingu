import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chingu/utils/encryption_helper.dart';

@GenerateMocks([FlutterSecureStorage])
import 'encryption_helper_test.mocks.dart';

void main() {
  late EncryptionHelper encryptionHelper;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    encryptionHelper = EncryptionHelper();
    encryptionHelper.setStorage(mockStorage);
  });

  group('EncryptionHelper', () {
    test('init generates and stores key if not exists', () async {
      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => null);

      await encryptionHelper.init();

      verify(mockStorage.read(key: 'app_encryption_key')).called(1);
      verify(mockStorage.write(key: 'app_encryption_key', value: anyNamed('value'))).called(1);
    });

    test('encrypt and decrypt work correctly', () async {
      final plainText = 'Hello World';

      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null); // Simulate no key, so it generates one
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => null);

      final encrypted = await encryptionHelper.encryptData(plainText);

      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plainText)));

      final decrypted = await encryptionHelper.decryptData(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('encrypts differently each time (IV check)', () async {
      final plainText = 'Hello World';

       when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => null);

      final encrypted1 = await encryptionHelper.encryptData(plainText);
      final encrypted2 = await encryptionHelper.encryptData(plainText);

      expect(encrypted1, isNot(equals(encrypted2)));

      expect(await encryptionHelper.decryptData(encrypted1), equals(plainText));
      expect(await encryptionHelper.decryptData(encrypted2), equals(plainText));
    });
  });
}

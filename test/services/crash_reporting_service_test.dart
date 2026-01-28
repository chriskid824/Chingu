import 'package:chingu/services/crash_reporting_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseCrashlytics])
import 'crash_reporting_service_test.mocks.dart';

void main() {
  late CrashReportingService crashReportingService;
  late MockFirebaseCrashlytics mockCrashlytics;

  setUp(() {
    mockCrashlytics = MockFirebaseCrashlytics();
    crashReportingService = CrashReportingService();
    crashReportingService.crashlytics = mockCrashlytics;
  });

  group('CrashReportingService', () {
    test('log should call crashlytics.log', () {
      const message = 'test log';
      crashReportingService.log(message);
      verify(mockCrashlytics.log(message)).called(1);
    });

    test('recordError should call crashlytics.recordError', () {
      final exception = Exception('test exception');
      final stack = StackTrace.current;
      crashReportingService.recordError(exception, stack, reason: 'test reason', fatal: true);
      verify(mockCrashlytics.recordError(exception, stack, reason: 'test reason', fatal: true)).called(1);
    });

    test('setUserIdentifier should call crashlytics.setUserIdentifier', () async {
      const identifier = 'user123';
      when(mockCrashlytics.setUserIdentifier(identifier)).thenAnswer((_) async => null);
      await crashReportingService.setUserIdentifier(identifier);
      verify(mockCrashlytics.setUserIdentifier(identifier)).called(1);
    });

    test('setCustomKey should call crashlytics.setCustomKey', () async {
      const key = 'testKey';
      const value = 'testValue';
      when(mockCrashlytics.setCustomKey(key, value)).thenAnswer((_) async => null);
      await crashReportingService.setCustomKey(key, value);
      verify(mockCrashlytics.setCustomKey(key, value)).called(1);
    });

    test('initialize should disable collection in debug mode (test environment)', () async {
      // In test environment, kDebugMode is usually true.
      when(mockCrashlytics.setCrashlyticsCollectionEnabled(false)).thenAnswer((_) async => null);

      await crashReportingService.initialize();

      verify(mockCrashlytics.setCrashlyticsCollectionEnabled(false)).called(1);
    });
  });
}

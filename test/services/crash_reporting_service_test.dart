import 'package:chingu/services/crash_reporting_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseCrashlytics])
import 'crash_reporting_service_test.mocks.dart';

void main() {
  late CrashReportingService service;
  late MockFirebaseCrashlytics mockCrashlytics;

  setUp(() {
    mockCrashlytics = MockFirebaseCrashlytics();
    service = CrashReportingService();
    service.crashlyticsOverride = mockCrashlytics;
  });

  test('initialize disables collection in debug mode (default in tests)', () async {
    // In tests, kDebugMode is usually true.
    // So we expect setCrashlyticsCollectionEnabled(false).

    when(mockCrashlytics.setCrashlyticsCollectionEnabled(any)).thenAnswer((_) async {});

    await service.initialize();

    verify(mockCrashlytics.setCrashlyticsCollectionEnabled(false)).called(1);
  });

  test('log calls crashlytics log', () {
    service.log('test message');
    verify(mockCrashlytics.log('test message')).called(1);
  });

  test('recordError calls crashlytics recordError', () async {
    final exception = Exception('oops');
    final stack = StackTrace.empty;

    when(mockCrashlytics.recordError(any, any, reason: anyNamed('reason'), fatal: anyNamed('fatal')))
        .thenAnswer((_) async {});

    await service.recordError(exception, stack, fatal: true);

    verify(mockCrashlytics.recordError(exception, stack, reason: null, fatal: true)).called(1);
  });

  test('enableCollection calls setCrashlyticsCollectionEnabled', () async {
    when(mockCrashlytics.setCrashlyticsCollectionEnabled(any)).thenAnswer((_) async {});

    await service.enableCollection(true);

    verify(mockCrashlytics.setCrashlyticsCollectionEnabled(true)).called(1);
  });
}

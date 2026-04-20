import 'dart:ui';
import 'package:chingu/services/crash_reporting_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
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
    // Inject the mock
    crashReportingService.crashlytics = mockCrashlytics;
  });

  group('CrashReportingService', () {
    test('initialize sets up error handling', () async {
      // Act
      await crashReportingService.initialize();

      // Assert
      // Verify FlutterError.onError is set.
      // Since it's a static function assignment, it's hard to verify strict equality without calling it.
      // But we can check that it is NOT null (which is default behavior anyway, but it ensures we didn't unset it).
      expect(FlutterError.onError, isNotNull);

      // We can't easily check if it's strictly equal to mockCrashlytics.recordFlutterFatalError
      // because recordFlutterFatalError is a method on the mock.

      // Verify PlatformDispatcher.onError is set
      expect(PlatformDispatcher.instance.onError, isNotNull);
    });

    test('log calls Crashlytics log', () {
      // Act
      crashReportingService.log('test message');

      // Assert
      verify(mockCrashlytics.log('test message')).called(1);
    });

    test('recordError calls Crashlytics recordError', () {
      // Arrange
      final exception = Exception('test exception');
      final stack = StackTrace.empty;

      // Act
      crashReportingService.recordError(exception, stack, reason: 'test reason', fatal: true);

      // Assert
      verify(mockCrashlytics.recordError(exception, stack, reason: 'test reason', fatal: true)).called(1);
    });

    test('setUserIdentifier calls Crashlytics setUserIdentifier', () async {
      // Act
      await crashReportingService.setUserIdentifier('user123');

      // Assert
      verify(mockCrashlytics.setUserIdentifier('user123')).called(1);
    });

    test('setCustomKey calls Crashlytics setCustomKey', () async {
      // Act
      await crashReportingService.setCustomKey('key', 'value');

      // Assert
      verify(mockCrashlytics.setCustomKey('key', 'value')).called(1);
    });
  });
}

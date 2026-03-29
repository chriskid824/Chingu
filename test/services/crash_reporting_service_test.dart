import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:chingu/services/crash_reporting_service.dart';

class FakeFirebaseCrashlytics extends Fake implements FirebaseCrashlytics {
  bool collectionEnabled = true; // Default usually depends, but we track the setter
  List<String> logs = [];
  List<Map<String, dynamic>> errors = [];
  String? userIdentifier;
  Map<String, Object> customKeys = {};
  List<FlutterErrorDetails> fatalErrors = [];

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> log(String message) async {
    logs.add(message);
  }

  @override
  Future<void> recordError(dynamic exception, StackTrace? stack,
      {dynamic reason,
      Iterable<Object> information = const [],
      bool fatal = false,
      bool? printDetails}) async {
    errors.add({
      'exception': exception,
      'stack': stack,
      'reason': reason,
      'fatal': fatal
    });
  }

  @override
  Future<void> recordFlutterFatalError(
      FlutterErrorDetails flutterErrorDetails) async {
    fatalErrors.add(flutterErrorDetails);
  }

  @override
  Future<void> setUserIdentifier(String identifier) async {
    userIdentifier = identifier;
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    customKeys[key] = value;
  }

  @override
  bool get isCrashlyticsCollectionEnabled => collectionEnabled;
}

void main() {
  group('CrashReportingService', () {
    late CrashReportingService crashReportingService;
    late FakeFirebaseCrashlytics fakeCrashlytics;

    setUp(() {
      fakeCrashlytics = FakeFirebaseCrashlytics();
      crashReportingService = CrashReportingService();
      crashReportingService.setMock(fakeCrashlytics);
    });

    test('initialize enables/disables collection based on debug mode', () async {
      await crashReportingService.initialize();

      // In test environment, kDebugMode is true.
      if (kDebugMode) {
        expect(fakeCrashlytics.collectionEnabled, false);
      } else {
        expect(fakeCrashlytics.collectionEnabled, true);
      }
    });

    test('log calls Crashlytics log', () async {
      const message = 'test log';
      await crashReportingService.log(message);
      expect(fakeCrashlytics.logs, contains(message));
    });

    test('recordError calls Crashlytics recordError', () async {
      final exception = Exception('test exception');
      final stack = StackTrace.empty;

      await crashReportingService.recordError(exception, stack,
          reason: 'test reason', fatal: true);

      expect(fakeCrashlytics.errors, isNotEmpty);
      final error = fakeCrashlytics.errors.first;
      expect(error['exception'], exception);
      expect(error['stack'], stack);
      expect(error['reason'], 'test reason');
      expect(error['fatal'], true);
    });

    test('setUserIdentifier calls Crashlytics setUserIdentifier', () async {
      const identifier = 'user123';
      await crashReportingService.setUserIdentifier(identifier);
      expect(fakeCrashlytics.userIdentifier, identifier);
    });

    test('setCustomKey calls Crashlytics setCustomKey', () async {
      const key = 'test_key';
      const value = 'test_value';
      await crashReportingService.setCustomKey(key, value);
      expect(fakeCrashlytics.customKeys[key], value);
    });
  });
}

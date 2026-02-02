import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();

  factory CrashReportingService() => _instance;

  CrashReportingService._internal();

  Future<void> initialize() async {
    if (kDebugMode) {
      // Force disable Crashlytics collection while doing every day development.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    } else {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }

  /// Log a message to Crashlytics
  void log(String message) {
    FirebaseCrashlytics.instance.log(message);
  }

  /// Record an error to Crashlytics
  void recordError(dynamic exception, StackTrace? stack, {dynamic reason, bool fatal = false}) {
    FirebaseCrashlytics.instance.recordError(exception, stack, reason: reason, fatal: fatal);
  }

  /// Set a user identifier for crash reports
  Future<void> setUserIdentifier(String identifier) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
  }

  /// Set custom keys for crash reports
  Future<void> setCustomKey(String key, Object value) async {
    await FirebaseCrashlytics.instance.setCustomKey(key, value);
  }
}

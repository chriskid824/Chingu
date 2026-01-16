import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();

  factory CrashReportingService() => _instance;

  CrashReportingService._internal();

  Future<void> initialize() async {
    // Conditionally enable/disable Crashlytics collection based on debug mode.
    // In debug mode, we don't want to spam Crashlytics, but we still want local logs.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Log a message to Crashlytics
  void log(String message) {
    if (kDebugMode) {
      debugPrint('[CrashReporting] Log: $message');
    }
    FirebaseCrashlytics.instance.log(message);
  }

  /// Record an error to Crashlytics
  void recordError(dynamic exception, StackTrace? stack, {dynamic reason, bool fatal = false}) {
    if (kDebugMode) {
      debugPrint('[CrashReporting] Error: $exception');
      if (stack != null) {
        debugPrintStack(stackTrace: stack, label: '[CrashReporting] Stack');
      }
      if (reason != null) {
        debugPrint('[CrashReporting] Reason: $reason');
      }
    }
    FirebaseCrashlytics.instance.recordError(exception, stack, reason: reason, fatal: fatal);
  }

  /// Set a user identifier for crash reports
  Future<void> setUserIdentifier(String identifier) async {
    if (kDebugMode) {
      debugPrint('[CrashReporting] Set User ID: $identifier');
    }
    await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
  }

  /// Set custom keys for crash reports
  Future<void> setCustomKey(String key, Object value) async {
    if (kDebugMode) {
      debugPrint('[CrashReporting] Set Key: $key = $value');
    }
    await FirebaseCrashlytics.instance.setCustomKey(key, value);
  }
}

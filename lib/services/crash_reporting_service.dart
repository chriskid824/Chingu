import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();

  factory CrashReportingService() => _instance;

  CrashReportingService._internal();

  Future<void> initialize() async {
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    if (kDebugMode) {
      // Force disable Crashlytics collection while doing every day development.
      // Temporarily toggle this to true if you want to test crash reporting in your app.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    } else {
      // Enable Crashlytics collection in release mode.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }
  }

  /// Log a message to Crashlytics
  void log(String message) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.log(message);
    } else {
      debugPrint('[Crashlytics Log] $message');
    }
  }

  /// Record an error to Crashlytics
  void recordError(dynamic exception, StackTrace? stack, {dynamic reason, bool fatal = false}) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(exception, stack, reason: reason, fatal: fatal);
    } else {
      debugPrint('[Crashlytics Error] $exception\n$stack');
    }
  }

  /// Set a user identifier for crash reports
  Future<void> setUserIdentifier(String identifier) async {
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
    }
  }

  /// Set custom keys for crash reports
  Future<void> setCustomKey(String key, Object value) async {
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    }
  }
}

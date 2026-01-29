import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  // Singleton pattern
  static final CrashReportingService _instance = CrashReportingService._internal();

  factory CrashReportingService() {
    return _instance;
  }

  CrashReportingService._internal();

  /// Initialize Crashlytics and set up global error handling
  Future<void> initialize() async {
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // In debug mode, we might want to disable collection to avoid spamming the console
    // or keep it enabled to test. For now, we follow default behavior or enforce enabling if needed.
    // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  /// Log a specific error manually
  Future<void> logError(dynamic exception, StackTrace? stack, {dynamic reason, bool fatal = false}) async {
    await FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Log a custom message to be included in the crash report
  Future<void> logMessage(String message) async {
    await FirebaseCrashlytics.instance.log(message);
  }

  /// Set user identifier to track who experienced the crash
  Future<void> setUserIdentifier(String identifier) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
  }
}

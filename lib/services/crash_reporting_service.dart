import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();

  factory CrashReportingService() => _instance;

  CrashReportingService._internal();

  FirebaseCrashlytics? _crashlyticsOverride;

  FirebaseCrashlytics get _crashlytics => _crashlyticsOverride ?? FirebaseCrashlytics.instance;

  @visibleForTesting
  set crashlytics(FirebaseCrashlytics value) => _crashlyticsOverride = value;

  Future<void> initialize() async {
    if (kDebugMode) {
      // Force disable Crashlytics collection while doing every day development.
      await _crashlytics.setCrashlyticsCollectionEnabled(false);
    } else {
      await _crashlytics.setCrashlyticsCollectionEnabled(true);

      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = _crashlytics.recordFlutterFatalError;

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }

  /// Log a message to Crashlytics
  void log(String message) {
    _crashlytics.log(message);
  }

  /// Record an error to Crashlytics
  void recordError(dynamic exception, StackTrace? stack, {dynamic reason, bool fatal = false}) {
    _crashlytics.recordError(exception, stack, reason: reason, fatal: fatal);
  }

  /// Set a user identifier for crash reports
  Future<void> setUserIdentifier(String identifier) async {
    await _crashlytics.setUserIdentifier(identifier);
  }

  /// Set custom keys for crash reports
  Future<void> setCustomKey(String key, Object value) async {
    await _crashlytics.setCustomKey(key, value);
  }
}

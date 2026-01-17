import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();

  FirebaseCrashlytics? _crashlytics;

  factory CrashReportingService() => _instance;

  CrashReportingService._internal();

  /// Inject a mock instance for testing
  @visibleForTesting
  void setMock(FirebaseCrashlytics mock) {
    _crashlytics = mock;
  }

  FirebaseCrashlytics get _api => _crashlytics ?? FirebaseCrashlytics.instance;

  Future<void> initialize() async {
    // Enable/disable Crashlytics based on debug mode
    if (kDebugMode) {
      await _api.setCrashlyticsCollectionEnabled(false);
    } else {
      await _api.setCrashlyticsCollectionEnabled(true);
    }

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = _api.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      _api.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Log a message to Crashlytics
  Future<void> log(String message) async {
    await _api.log(message);
  }

  /// Record an error to Crashlytics
  Future<void> recordError(dynamic exception, StackTrace? stack,
      {dynamic reason, bool fatal = false}) async {
    await _api.recordError(exception, stack, reason: reason, fatal: fatal);
  }

  /// Set a user identifier for crash reports
  Future<void> setUserIdentifier(String identifier) async {
    await _api.setUserIdentifier(identifier);
  }

  /// Set custom keys for crash reports
  Future<void> setCustomKey(String key, Object value) async {
    await _api.setCustomKey(key, value);
  }
}

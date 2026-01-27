import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  static final CrashReportingService _instance =
      CrashReportingService._internal();

  factory CrashReportingService() => _instance;

  CrashReportingService._internal();

  @visibleForTesting
  FirebaseCrashlytics? crashlyticsOverride;

  FirebaseCrashlytics get _crashlytics =>
      crashlyticsOverride ?? FirebaseCrashlytics.instance;

  Future<void> initialize() async {
    // 根據是否為 Debug 模式設定是否收集崩潰報告
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = _crashlytics.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Manually enable or disable collection
  Future<void> enableCollection(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  /// Log a message to Crashlytics
  void log(String message) {
    _crashlytics.log(message);
  }

  /// Record an error to Crashlytics
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
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

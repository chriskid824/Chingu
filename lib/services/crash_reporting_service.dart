import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();

  factory CrashReportingService() => _instance;

  CrashReportingService._internal();

  Future<void> initialize() async {
    // 根據模式設置是否收集 Crashlytics 數據
    if (kDebugMode) {
      // 在 Debug 模式下禁用 Crashlytics 收集，避免污染數據
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    } else {
      // 在 Release 模式下啟用 Crashlytics 收集
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = (errorDetails) {
      if (kDebugMode) {
        // 在 Debug 模式下，將錯誤打印到控制台
        FlutterError.dumpErrorToConsole(errorDetails);
      } else {
        // 在 Release 模式下，上報到 Crashlytics
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      }
    };

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        // 在 Debug 模式下，讓錯誤冒泡（打印到控制台）
        return false;
      } else {
        // 在 Release 模式下，上報到 Crashlytics 並標記為致命錯誤
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      }
    };
  }

  /// Log a message to Crashlytics (breadcrumbs)
  Future<void> log(String message) async {
    await FirebaseCrashlytics.instance.log(message);
  }

  /// Record an error to Crashlytics
  Future<void> recordError(dynamic exception, StackTrace? stack,
      {dynamic reason, bool fatal = false}) async {
    await FirebaseCrashlytics.instance
        .recordError(exception, stack, reason: reason, fatal: fatal);
  }

  /// Set a user identifier for crash reports
  Future<void> setUserIdentifier(String identifier) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
  }

  /// Set custom keys for crash reports
  Future<void> setCustomKey(String key, Object value) async {
    await FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  /// Toggle collection manually (useful for user settings or testing)
  Future<void> toggleCollection(bool enabled) async {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
  }
}

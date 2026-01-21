import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AnalyticsService {
  // Private constructor
  AnalyticsService._();

  // Singleton instance
  static final AnalyticsService _instance = AnalyticsService._();

  // Factory constructor
  factory AnalyticsService() => _instance;

  // FirebaseAnalytics instance
  FirebaseAnalytics? _analytics;

  FirebaseAnalytics? get _safeAnalytics {
    if (_analytics == null) {
      try {
        _analytics = FirebaseAnalytics.instance;
      } catch (e) {
        if (kDebugMode) {
          print('FirebaseAnalytics not initialized: $e');
        }
      }
    }
    return _analytics;
  }

  /// Get the navigator observer for tracking screen views
  NavigatorObserver get observer {
    final analytics = _safeAnalytics;
    if (analytics != null) {
      return FirebaseAnalyticsObserver(analytics: analytics);
    }
    return NavigatorObserver();
  }

  /// Log a custom event
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    final analytics = _safeAnalytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log event: $e');
      }
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    final analytics = _safeAnalytics;
    if (analytics == null) return;
    try {
      await analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log screen view: $e');
      }
    }
  }

  /// Log login event
  Future<void> logLogin({required String method}) async {
    final analytics = _safeAnalytics;
    if (analytics == null) return;
    try {
      await analytics.logLogin(loginMethod: method);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log login: $e');
      }
    }
  }

  /// Log sign up event
  Future<void> logSignUp({required String method}) async {
    final analytics = _safeAnalytics;
    if (analytics == null) return;
    try {
      await analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log sign up: $e');
      }
    }
  }

  /// Set user ID
  Future<void> setUserId(String? id) async {
    final analytics = _safeAnalytics;
    if (analytics == null) return;
    try {
      await analytics.setUserId(id: id);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set user ID: $e');
      }
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    final analytics = _safeAnalytics;
    if (analytics == null) return;
    try {
      await analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set user property: $e');
      }
    }
  }
}

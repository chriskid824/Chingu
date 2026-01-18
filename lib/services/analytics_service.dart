import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  AnalyticsService._internal();

  FirebaseAnalytics? _analyticsInstance;

  /// Sets the FirebaseAnalytics instance for testing.
  @visibleForTesting
  set analyticsInstance(FirebaseAnalytics analytics) {
    _analyticsInstance = analytics;
  }

  FirebaseAnalytics get _analytics => _analyticsInstance ?? FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Logs a custom event with optional parameters.
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('Analytics Event Logged: $name, params: $parameters');
    } catch (e) {
      debugPrint('Failed to log analytics event: $e');
    }
  }

  /// Logs a screen view.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      debugPrint('Analytics Screen View Logged: $screenName');
    } catch (e) {
      debugPrint('Failed to log screen view: $e');
    }
  }

  /// Sets the user ID.
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
      debugPrint('Analytics User ID set: $id');
    } catch (e) {
      debugPrint('Failed to set analytics user ID: $e');
    }
  }

  /// Sets a user property.
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      debugPrint('Analytics User Property set: $name = $value');
    } catch (e) {
      debugPrint('Failed to set analytics user property: $e');
    }
  }

  /// Logs a login event.
  Future<void> logLogin({String? method}) async {
    await logEvent(
      'login',
      parameters: method != null ? {'method': method} : null,
    );
  }

  /// Logs a sign up event.
  Future<void> logSignUp({String? method}) async {
    await logEvent(
      'sign_up',
      parameters: method != null ? {'method': method} : null,
    );
  }
}

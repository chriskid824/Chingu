import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  FirebaseAnalytics? _mockAnalytics;

  FirebaseAnalytics get _analytics => _mockAnalytics ?? FirebaseAnalytics.instance;

  /// Set a mock instance for testing
  @visibleForTesting
  void setMockInstance(FirebaseAnalytics mock) {
    _mockAnalytics = mock;
  }

  /// Get the analytics observer for navigation tracking
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  /// Log a screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  /// Set the user ID
  Future<void> setUserId(String? id) async {
    await _analytics.setUserId(id: id);
  }

  /// Set a user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Log a login event
  Future<void> logLogin({String? method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Log a sign up event
  Future<void> logSignUp({required String signUpMethod}) async {
    await _analytics.logSignUp(signUpMethod: signUpMethod);
  }
}

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  FirebaseAnalytics? _analyticsInstance;

  FirebaseAnalytics get _analytics =>
      _analyticsInstance ?? FirebaseAnalytics.instance;

  @visibleForTesting
  set analytics(FirebaseAnalytics analytics) {
    _analyticsInstance = analytics;
  }

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
    } catch (e) {
      debugPrint('Error setting user id: $e');
    }
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Error setting user property: $e');
    }
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Error logging login: $e');
    }
  }

  Future<void> logSignUp({String? method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method ?? 'email');
    } catch (e) {
      debugPrint('Error logging sign up: $e');
    }
  }

  Future<void> logTutorialBegin() async {
    try {
      await _analytics.logTutorialBegin();
    } catch (e) {
      debugPrint('Error logging tutorial begin: $e');
    }
  }

  Future<void> logTutorialComplete() async {
    try {
      await _analytics.logTutorialComplete();
    } catch (e) {
      debugPrint('Error logging tutorial complete: $e');
    }
  }
}

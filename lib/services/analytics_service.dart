import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      if (kDebugMode) {
        print('Analytics Event: $name, params: $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics error (logEvent): $e');
      }
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
      if (kDebugMode) {
        print('Analytics Screen: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics error (logScreenView): $e');
      }
    }
  }

  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      if (kDebugMode) {
        print('Analytics Login: $method');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics error (logLogin): $e');
      }
    }
  }

  Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      if (kDebugMode) {
        print('Analytics SignUp: $method');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics error (logSignUp): $e');
      }
    }
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        print('Analytics UserProperty: $name = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics error (setUserProperty): $e');
      }
    }
  }

  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
      if (kDebugMode) {
        print('Analytics UserId: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics error (setUserId): $e');
      }
    }
  }
}

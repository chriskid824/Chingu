import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics service to track user events and screen views.
/// Wraps FirebaseAnalytics.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Logs a custom event with optional parameters.
  Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      if (kDebugMode) {
        debugPrint('[Analytics] Event: $name, Params: $parameters');
      }
    } catch (e) {
      debugPrint('[Analytics] Error logging event $name: $e');
    }
  }

  /// Logs a screen view event.
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
      );
      if (kDebugMode) {
        debugPrint('[Analytics] Screen View: $screenName');
      }
    } catch (e) {
      debugPrint('[Analytics] Error logging screen view $screenName: $e');
    }
  }

  /// Sets a user property.
  Future<void> setUserProperty({required String name, required String? value}) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('[Analytics] Error setting user property $name: $e');
    }
  }

  /// Sets the user ID.
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
    } catch (e) {
      debugPrint('[Analytics] Error setting user ID: $e');
    }
  }
}

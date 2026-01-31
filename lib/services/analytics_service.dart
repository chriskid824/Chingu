import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Firebase Analytics strict casting to Map<String, Object>
      final Map<String, Object>? cleanParams = parameters?.map((key, value) {
        return MapEntry(key, value as Object);
      });

      await _analytics.logEvent(
        name: name,
        parameters: cleanParams,
      );

      if (kDebugMode) {
        print('[Analytics] Logged event: $name, params: $cleanParams');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Analytics] Error logging event $name: $e');
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
        print('[Analytics] Set user property: $name = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Analytics] Error setting user property $name: $e');
      }
    }
  }

  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
      if (kDebugMode) {
        print('[Analytics] Set user ID: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Analytics] Error setting user ID: $e');
      }
    }
  }
}

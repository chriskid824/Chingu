import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  AnalyticsService._internal();

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  /// Initialize the service
  Future<void> initialize() async {
    // Analytics collection is enabled by default, but we can explicit set it here if needed.
    // await _analytics.setAnalyticsCollectionEnabled(true);
  }

  /// Returns the observer for tracking navigation events
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

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

  /// Set the user ID
  Future<void> setUserId(String? id) async {
    await _analytics.setUserId(id: id);
  }

  /// Set a user property
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Manually log a screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }
}

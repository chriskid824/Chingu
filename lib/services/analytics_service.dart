import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service for tracking user activity and events using Firebase Analytics.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  late FirebaseAnalytics _analytics;
  late FirebaseAnalyticsObserver _observer;
  bool _initialized = false;

  AnalyticsService._internal();

  /// Initialize the Analytics Service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics);
      _initialized = true;
      debugPrint('AnalyticsService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AnalyticsService: $e');
    }
  }

  /// Get the analytics observer for navigation tracking
  FirebaseAnalyticsObserver get observer {
    if (!_initialized) {
      debugPrint('Warning: AnalyticsService not initialized, returning uninitialized observer');
      // In a real scenario, this might be risky, but we rely on initialize() being called in main.dart
      // If we create observer here without instance, it might fail.
      // Assuming initialize is called. If not, we try to init here synchronously which is not possible for async method,
      // but FirebaseAnalytics.instance is synchronous getter usually.
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics);
      _initialized = true;
    }
    return _observer;
  }

  // Wrapper methods for common events

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_initialized) return;

    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      if (kDebugMode) {
        debugPrint('Analytics Event: $name, params: $parameters');
      }
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  /// Log when a user logs in
  Future<void> logLogin({String? method}) async {
    if (!_initialized) return;
    await _analytics.logLogin(loginMethod: method);
    if (kDebugMode) {
      debugPrint('Analytics Login: $method');
    }
  }

  /// Log when a user signs up
  Future<void> logSignUp({String? method}) async {
    if (!_initialized) return;
    await _analytics.logSignUp(signupMethod: method ?? 'email');
    if (kDebugMode) {
      debugPrint('Analytics SignUp: $method');
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_initialized) return;
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
    if (kDebugMode) {
      debugPrint('Analytics ScreenView: $screenName');
    }
  }

  /// Set user ID
  Future<void> setUserId(String? id) async {
    if (!_initialized) return;
    await _analytics.setUserId(id: id);
    if (kDebugMode) {
      debugPrint('Analytics Set User ID: $id');
    }
  }

  /// Set user properties
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_initialized) return;
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Feature specific logs

  Future<void> logSwipe(String type, bool isMatch) async {
    await logEvent(
      name: 'swipe_action',
      parameters: {
        'swipe_type': type,
        'is_match': isMatch ? 1 : 0,
      },
    );
  }

  Future<void> logSendMessage(String type) async {
    await logEvent(
      name: 'send_message',
      parameters: {
        'message_type': type,
      },
    );
  }

  Future<void> logJoinEvent(String eventId) async {
    await logEvent(
      name: 'join_event',
      parameters: {
        'event_id': eventId,
      },
    );
  }

  Future<void> logLeaveEvent(String eventId) async {
    await logEvent(
      name: 'leave_event',
      parameters: {
        'event_id': eventId,
      },
    );
  }
}

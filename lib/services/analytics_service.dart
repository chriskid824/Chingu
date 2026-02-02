import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;

  /// Visible for testing to inject mock instance
  @visibleForTesting
  set analytics(FirebaseAnalytics value) {
    _analytics = value;
  }

  FirebaseAnalytics get analytics {
    _analytics ??= FirebaseAnalytics.instance;
    return _analytics!;
  }

  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      await analytics.logEvent(name: name, parameters: parameters);
      debugPrint('Analytics: Event $name logged with $parameters');
    } catch (e) {
      debugPrint('Analytics: Failed to log event $name: $e');
    }
  }

  Future<void> logNotificationReceived({
    required String notificationId,
    required String variant,
  }) async {
    await logEvent('notification_received', {
      'notification_id': notificationId,
      'variant': variant,
    });
  }

  Future<void> logNotificationClicked({
    required String notificationId,
    required String variant,
    String? actionId,
  }) async {
    await logEvent('notification_clicked', {
      'notification_id': notificationId,
      'variant': variant,
      if (actionId != null) 'action_id': actionId,
    });
  }

  NavigatorObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: analytics);
  }
}

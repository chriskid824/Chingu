import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      if (kDebugMode) {
        print('Analytics Event: $name, params: $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging analytics event: $e');
      }
    }
  }

  Future<void> logNotificationSent({
    required String notificationId,
    required String type,
    required String group, // 'control' or 'variant'
  }) async {
    await logEvent('notification_sent', parameters: {
      'notification_id': notificationId,
      'notification_type': type,
      'ab_group': group,
    });
  }

  Future<void> logNotificationClicked({
    required String notificationId,
    required String type,
    String? group, // Optional because we might not have it in the click payload unless we pass it
    String? actionId,
  }) async {
    await logEvent('notification_clicked', parameters: {
      'notification_id': notificationId,
      'notification_type': type,
      if (group != null) 'ab_group': group,
      if (actionId != null) 'action_id': actionId,
    });
  }

  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> logLogin() async {
    await _analytics.logLogin();
  }

  Future<void> logSignUp() async {
    await _analytics.logSignUp(signUpMethod: 'email');
  }

  FirebaseAnalyticsObserver getObserver() {
     return FirebaseAnalyticsObserver(analytics: _analytics);
  }
}

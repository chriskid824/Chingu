import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// 記錄一般事件
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('Analytics Event: $name, params: $parameters');
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  /// 設置用戶 ID
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
      debugPrint('Analytics Set User ID: $id');
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  /// 設置用戶屬性
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  /// 記錄登入
  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      debugPrint('Analytics Login: $method');
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  /// 記錄註冊
  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      debugPrint('Analytics SignUp: $method');
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  /// 記錄滑動操作 (喜歡/不喜歡)
  Future<void> logSwipe({
    required String targetUserId,
    required bool isLike,
  }) async {
    await logEvent('swipe_action', {
      'target_user_id': targetUserId,
      'action': isLike ? 'like' : 'dislike',
    });
  }

  /// 記錄配對成功
  Future<void> logMatch({
    required String partnerId,
  }) async {
    await logEvent('match_success', {
      'partner_id': partnerId,
    });
  }

  /// 記錄頁面瀏覽 (手動)
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      debugPrint('Analytics Screen View: $screenName');
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }
}

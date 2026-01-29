import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// 用戶行為追蹤服務
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  late final FirebaseAnalytics _analytics;

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal() {
    _analytics = FirebaseAnalytics.instance;
  }

  /// 獲取 Analytics 實例
  FirebaseAnalytics get analytics => _analytics;

  /// 獲取導航觀察者，用於自動追蹤頁面瀏覽
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// 記錄一般事件
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
        debugPrint('Analytics Event: $name, params: $parameters');
      }
    } catch (e) {
      debugPrint('Error logging analytics event: $e');
    }
  }

  /// 記錄登入事件
  Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
    if (kDebugMode) {
      debugPrint('Analytics Login: $method');
    }
  }

  /// 記錄註冊事件
  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
    if (kDebugMode) {
      debugPrint('Analytics SignUp: $method');
    }
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
      if (kDebugMode) {
        debugPrint('Analytics Screen View: $screenName');
      }
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  /// 設置用戶屬性
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

  /// 設置用戶 ID
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
      if (kDebugMode) {
        debugPrint('Analytics User ID set to: $id');
      }
    } catch (e) {
      debugPrint('Error setting user ID: $e');
    }
  }
}

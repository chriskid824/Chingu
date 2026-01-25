import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// 分析服務 - 負責追蹤用戶行為與數據
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  AnalyticsService._internal();

  /// 獲取導航觀察者
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// 記錄自定義事件
  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      if (kDebugMode) {
        debugPrint('[Analytics] Logged event: $name, params: $parameters');
      }
    } catch (e) {
      debugPrint('[Analytics] Error logging event: $e');
    }
  }

  /// 記錄頁面瀏覽
  Future<void> logScreenView(
    String screenName, {
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('[Analytics] Error logging screen view: $e');
    }
  }

  /// 設置用戶 ID
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
      if (kDebugMode) {
        debugPrint('[Analytics] Set User ID: $id');
      }
    } catch (e) {
      debugPrint('[Analytics] Error setting user ID: $e');
    }
  }

  /// 設置用戶屬性
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      debugPrint('[Analytics] Error setting user property: $e');
    }
  }

  /// 記錄登入
  Future<void> logLogin({required String method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      if (kDebugMode) {
        debugPrint('[Analytics] Logged login: $method');
      }
    } catch (e) {
      debugPrint('[Analytics] Error logging login: $e');
    }
  }

  /// 記錄註冊
  Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      if (kDebugMode) {
        debugPrint('[Analytics] Logged sign up: $method');
      }
    } catch (e) {
      debugPrint('[Analytics] Error logging sign up: $e');
    }
  }
}

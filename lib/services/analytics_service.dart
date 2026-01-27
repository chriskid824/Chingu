import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  FirebaseAnalytics? _analyticsInstance;

  @visibleForTesting
  void setAnalyticsForTest(FirebaseAnalytics analytics) {
    _analyticsInstance = analytics;
  }

  FirebaseAnalytics get _analytics =>
      _analyticsInstance ??= FirebaseAnalytics.instance;

  /// 獲取導航觀察者，用於自動追蹤頁面瀏覽
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  /// 記錄自定義事件
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics logEvent error: $e');
      }
    }
  }

  /// 記錄螢幕瀏覽（手動）
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics logScreenView error: $e');
      }
    }
  }

  /// 設定用戶 ID
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
    } catch (e) {
      if (kDebugMode) {
        print('Analytics setUserId error: $e');
      }
    }
  }

  /// 設定用戶屬性
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics setUserProperty error: $e');
      }
    }
  }
}

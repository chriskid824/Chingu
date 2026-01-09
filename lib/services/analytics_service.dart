import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// 分析服務 - 處理所有 Firebase Analytics 相關操作
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  /// 獲取 analytics 實例
  FirebaseAnalytics get analytics => _analytics;

  /// 獲取 navigator observer
  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// 設置用戶 ID
  /// 當用戶登入時調用
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
    debugPrint('Analytics: User ID set to $userId');
  }

  /// 設置用戶屬性
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// 記錄事件
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
    debugPrint('Analytics: Event $name logged with parameters: $parameters');
  }

  /// 記錄頁面瀏覽
  ///
  /// [screenName] 頁面名稱
  /// [screenClass] 頁面類別 (可選)
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
    debugPrint('Analytics: Screen view logged: $screenName');
  }

  /// 記錄功能使用
  ///
  /// [featureName] 功能名稱
  /// [action] 動作 (e.g., 'start', 'complete', 'click')
  Future<void> logFeatureUsage({
    required String featureName,
    required String action,
    Map<String, Object>? additionalParams,
  }) async {
    final params = <String, Object>{
      'feature_name': featureName,
      'action': action,
    };
    if (additionalParams != null) {
      params.addAll(additionalParams);
    }

    await logEvent(
      name: 'feature_usage',
      parameters: params,
    );
  }

  /// 記錄註冊流程
  Future<void> logSignUp({
    required String method,
  }) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  /// 記錄登入
  Future<void> logLogin({
    required String method,
  }) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// 記錄搜尋
  Future<void> logSearch({
    required String searchTerm,
  }) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }
}

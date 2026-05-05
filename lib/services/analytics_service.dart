import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// 用於追蹤用戶行為的分析服務
/// 封裝 Firebase Analytics 以提供統一的事件記錄接口
class AnalyticsService {
  // 單例模式
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;

  /// 初始化服務
  Future<void> initialize() async {
    // 確保 Firebase Analytics 實例已創建
    _analytics = FirebaseAnalytics.instance;
    debugPrint('AnalyticsService initialized');
  }

  /// 獲取導航觀察者，用於自動追蹤頁面瀏覽
  NavigatorObserver getAnalyticsObserver() {
    if (_analytics == null) {
      _analytics = FirebaseAnalytics.instance;
    }
    return FirebaseAnalyticsObserver(analytics: _analytics!);
  }

  /// 記錄自定義事件
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics?.logEvent(
        name: name,
        parameters: parameters,
      );
      if (kDebugMode) {
        debugPrint('Analytics Event: $name, Parameters: $parameters');
      }
    } catch (e) {
      debugPrint('Failed to log event: $e');
    }
  }

  /// 記錄頁面瀏覽（通常由 Observer 自動處理，但可手動調用）
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics?.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      if (kDebugMode) {
        debugPrint('Analytics Screen View: $screenName');
      }
    } catch (e) {
      debugPrint('Failed to log screen view: $e');
    }
  }

  /// 設置用戶 ID
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics?.setUserId(id: userId);
      if (kDebugMode) {
        debugPrint('Analytics User ID set: $userId');
      }
    } catch (e) {
      debugPrint('Failed to set user ID: $e');
    }
  }

  /// 設置用戶屬性
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics?.setUserProperty(
        name: name,
        value: value,
      );
      if (kDebugMode) {
        debugPrint('Analytics User Property: $name = $value');
      }
    } catch (e) {
      debugPrint('Failed to set user property: $e');
    }
  }

  /// 記錄登入事件
  Future<void> logLogin({
    String? method,
  }) async {
    try {
      await _analytics?.logLogin(loginMethod: method);
      if (kDebugMode) {
        debugPrint('Analytics Login: $method');
      }
    } catch (e) {
      debugPrint('Failed to log login: $e');
    }
  }

  /// 記錄註冊事件
  Future<void> logSignUp({
    required String method,
  }) async {
    try {
      await _analytics?.logSignUp(signUpMethod: method);
      if (kDebugMode) {
        debugPrint('Analytics Sign Up: $method');
      }
    } catch (e) {
      debugPrint('Failed to log sign up: $e');
    }
  }

  /// 記錄搜索事件
  Future<void> logSearch({
    required String searchTerm,
  }) async {
    try {
      await _analytics?.logSearch(searchTerm: searchTerm);
      if (kDebugMode) {
        debugPrint('Analytics Search: $searchTerm');
      }
    } catch (e) {
      debugPrint('Failed to log search: $e');
    }
  }

  /// 記錄查看內容事件
  Future<void> logViewContent({
    required String contentType,
    required String itemId,
  }) async {
    try {
      await _analytics?.logSelectContent(
        contentType: contentType,
        itemId: itemId,
      );
      if (kDebugMode) {
        debugPrint('Analytics View Content: $contentType - $itemId');
      }
    } catch (e) {
      debugPrint('Failed to log view content: $e');
    }
  }
}

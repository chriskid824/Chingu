import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// 負責處理所有應用程式分析與追蹤的服務
///
/// 封裝了 [FirebaseAnalytics] 的功能，提供統一的介面來記錄：
/// - 頁面瀏覽 (Screen Views)
/// - 用戶行為事件 (Events)
/// - 用戶屬性 (User Properties)
/// - 登入/註冊事件
class AnalyticsService {
  // 單例模式實作
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// 獲取 Analytics Observer 以用於 Navigator
  ///
  /// 這將自動追蹤路由變化作為頁面瀏覽
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  /// 記錄通用事件
  ///
  /// [name] 事件名稱 (例如: 'select_content', 'share_image')
  /// [parameters] 事件參數 (可選)
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
        debugPrint('[Analytics] Logged event: $name, params: $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Error logging event $name: $e');
      }
    }
  }

  /// 記錄頁面瀏覽
  ///
  /// 通常由 [FirebaseAnalyticsObserver] 自動處理，但也可以手動調用
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
        debugPrint('[Analytics] Logged screen view: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Error logging screen view $screenName: $e');
      }
    }
  }

  /// 記錄登入事件
  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      if (kDebugMode) {
        debugPrint('[Analytics] Logged login: method=$method');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Error logging login: $e');
      }
    }
  }

  /// 記錄註冊事件
  Future<void> logSignUp({required String signUpMethod}) async {
    try {
      await _analytics.logSignUp(signUpMethod: signUpMethod);
      if (kDebugMode) {
        debugPrint('[Analytics] Logged sign up: method=$signUpMethod');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Error logging sign up: $e');
      }
    }
  }

  /// 設置用戶 ID
  ///
  /// 當用戶登入後調用，用於關聯同一用戶的行為
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
      if (kDebugMode) {
        debugPrint('[Analytics] Set user ID: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Error setting user ID: $e');
      }
    }
  }

  /// 設置用戶屬性
  ///
  /// 用於標記用戶群體特徵 (例如: 'role', 'subscription_status')
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        debugPrint('[Analytics] Set user property: $name = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Error setting user property $name: $e');
      }
    }
  }

  /// 記錄特定功能使用
  ///
  /// 這是自定義事件的一個便利方法
  Future<void> logFeatureUse({
    required String featureName,
    Map<String, Object>? parameters,
  }) async {
    await logEvent(
      name: 'feature_use',
      parameters: {
        'feature_name': featureName,
        ...?parameters,
      },
    );
  }
}

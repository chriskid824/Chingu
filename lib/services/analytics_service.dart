import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// 用戶活躍度追蹤服務
///
/// 集成 Firebase Analytics，追蹤用戶行為（頁面瀏覽、功能使用）。
class AnalyticsService {
  // Singleton
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;

  /// 設置用戶 ID
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
      debugPrint('[Analytics] Set User ID: $id');
    } catch (e) {
      debugPrint('[Analytics] Set User ID failed: $e');
    }
  }

  /// 設置用戶屬性
  Future<void> setUserProperty({required String name, required String? value}) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      debugPrint('[Analytics] Set User Property: $name = $value');
    } catch (e) {
      debugPrint('[Analytics] Set User Property failed: $e');
    }
  }

  /// 記錄自定義事件
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('[Analytics] Log Event: $name, params: $parameters');
    } catch (e) {
      debugPrint('[Analytics] Log Event failed: $e');
    }
  }

  /// 記錄登入事件
  Future<void> logLogin({String? loginMethod}) async {
    try {
      await _analytics.logLogin(loginMethod: loginMethod);
      debugPrint('[Analytics] Log Login: $loginMethod');
    } catch (e) {
      debugPrint('[Analytics] Log Login failed: $e');
    }
  }

  /// 記錄註冊事件
  Future<void> logSignUp({required String signUpMethod}) async {
    try {
      await _analytics.logSignUp(signUpMethod: signUpMethod);
      debugPrint('[Analytics] Log Sign Up: $signUpMethod');
    } catch (e) {
      debugPrint('[Analytics] Log Sign Up failed: $e');
    }
  }

  /// 設置當前螢幕
  ///
  /// 注意：如果使用 FirebaseAnalyticsObserver，螢幕切換會自動追蹤，
  /// 只有在非導航切換的螢幕變化時才需要手動調用此方法。
  Future<void> setCurrentScreen({
    required String screenName,
    String? screenClassOverride,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClassOverride,
      );
      debugPrint('[Analytics] Set Current Screen: $screenName');
    } catch (e) {
      debugPrint('[Analytics] Set Current Screen failed: $e');
    }
  }
}

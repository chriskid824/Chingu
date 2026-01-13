import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver getObserver() {
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
      debugPrint('Analytics Event: $name, params: $parameters');
    } catch (e) {
      debugPrint('Failed to log event: $e');
    }
  }

  /// 設置用戶 ID
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
      debugPrint('Analytics User ID set to: $id');
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
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Failed to set user property: $e');
    }
  }

  /// 設置當前畫面
  Future<void> setCurrentScreen({
    required String screenName,
    String? screenClassOverride,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClassOverride,
      );
    } catch (e) {
      debugPrint('Failed to set current screen: $e');
    }
  }

  /// 記錄登入事件
  Future<void> logLogin({String? method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// 記錄註冊事件
  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  /// 記錄教學開始
  Future<void> logTutorialBegin() async {
    await _analytics.logTutorialBegin();
  }

  /// 記錄教學完成
  Future<void> logTutorialComplete() async {
    await _analytics.logTutorialComplete();
  }

  /// 記錄功能使用
  Future<void> logFeatureUsage(String featureName, {Map<String, Object>? parameters}) async {
    await logEvent(
      name: 'feature_usage',
      parameters: {
        'feature_name': featureName,
        ...?parameters,
      },
    );
  }
}

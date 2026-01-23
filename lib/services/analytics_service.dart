import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// 獲取 FirebaseAnalyticsObserver 用於自動追蹤導航
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  /// 記錄通用事件
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      if (kDebugMode) {
        print('Analytics Event: $name, params: $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log event: $e');
      }
    }
  }

  /// 記錄頁面瀏覽
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
        print('Failed to log screen view: $e');
      }
    }
  }

  /// 記錄登入事件
  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log login: $e');
      }
    }
  }

  /// 記錄註冊事件
  Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log sign up: $e');
      }
    }
  }

  /// 設置用戶 ID
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set user ID: $e');
      }
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
      if (kDebugMode) {
        print('Failed to set user property: $e');
      }
    }
  }
}

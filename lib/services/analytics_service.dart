import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal() {
    try {
      _analytics = FirebaseAnalytics.instance;
    } catch (e) {
      debugPrint('Firebase Analytics not initialized: $e');
    }
  }

  FirebaseAnalytics? _analytics;

  FirebaseAnalyticsObserver get observer {
    if (_analytics == null) {
      // 如果 _analytics 為 null，嘗試重新獲取
      try {
        _analytics = FirebaseAnalytics.instance;
      } catch (e) {
        throw Exception('Firebase Analytics not initialized');
      }
    }
    return FirebaseAnalyticsObserver(analytics: _analytics!);
  }

  /// 記錄自定義事件
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics error (logEvent): $e');
    }
  }

  /// 設置當前畫面
  Future<void> setCurrentScreen(String screenName,
      [String? screenClassOverride]) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClassOverride,
      );
    } catch (e) {
      debugPrint('Analytics error (setCurrentScreen): $e');
    }
  }

  /// 設置用戶 ID
  Future<void> setUserId(String? userId) async {
    if (_analytics == null) return;
    try {
      await _analytics!.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics error (setUserId): $e');
    }
  }

  /// 設置用戶屬性
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (_analytics == null) return;
    try {
      await _analytics!.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics error (setUserProperty): $e');
    }
  }

  // --- 預定義事件 ---

  /// 記錄登入
  Future<void> logLogin({required String method}) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics error (logLogin): $e');
    }
  }

  /// 記錄註冊
  Future<void> logSignUp({required String method}) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Analytics error (logSignUp): $e');
    }
  }

  /// 記錄加入晚餐活動
  Future<void> logJoinEvent(String eventId) async {
    await logEvent('join_dinner_event', {'event_id': eventId});
  }

  /// 記錄創建晚餐活動
  Future<void> logCreateEvent({
    String? eventId,
    required String city,
    required String district,
    required int budgetRange,
  }) async {
    await logEvent('create_dinner_event', {
      if (eventId != null) 'event_id': eventId,
      'city': city,
      'district': district,
      'budget_range': budgetRange,
    });
  }

  /// 記錄預約晚餐活動
  Future<void> logBookEvent({
    required String city,
    required String district,
    required DateTime date,
  }) async {
    await logEvent('book_dinner_event', {
      'city': city,
      'district': district,
      'date': date.toIso8601String(),
    });
  }
}

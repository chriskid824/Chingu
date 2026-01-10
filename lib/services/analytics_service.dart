import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// 使用 Firebase Analytics 追蹤用戶行為的服務
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// 獲取 Analytics Observer 以自動追蹤路由變化
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  /// 設置用戶 ID
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
    } catch (e) {
      debugPrint('Analytics setUserId error: $e');
    }
  }

  /// 設置用戶屬性
  Future<void> setUserProperty({required String name, required String value}) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics setUserProperty error: $e');
    }
  }

  // --- 預定義事件 ---

  /// 記錄登入事件
  Future<void> logLogin({String method = 'email'}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics logLogin error: $e');
    }
  }

  /// 記錄註冊事件
  Future<void> logSignUp({String method = 'email'}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Analytics logSignUp error: $e');
    }
  }

  /// 記錄頁面瀏覽 (通常由 Observer 自動處理，但可手動調用)
  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    try {
      await _analytics.logScreenView(screenName: screenName, screenClass: screenClass);
    } catch (e) {
      debugPrint('Analytics logScreenView error: $e');
    }
  }

  /// 記錄自定義事件
  Future<void> logEvent({required String name, Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics logEvent error: $e');
    }
  }

  // --- 業務特定事件 ---

  /// 記錄滑動配對事件
  Future<void> logSwipe({required String direction, required bool isMatch}) async {
    await logEvent(name: 'swipe', parameters: {
      'direction': direction,
      'is_match': isMatch ? 1 : 0,
    });
  }

  /// 記錄創建晚餐活動事件
  Future<void> logCreateEvent({required String category}) async {
    await logEvent(name: 'create_event', parameters: {
      'category': category,
    });
  }

  /// 記錄發送訊息事件
  Future<void> logSendMessage({required String type}) async {
    await logEvent(name: 'send_message', parameters: {
      'type': type,
    });
  }
}

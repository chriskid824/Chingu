import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// 回傳 FirebaseAnalyticsObserver 用於導航觀察
  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// 通用事件記錄
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
        debugPrint('Analytics Event: $name, Params: $parameters');
      }
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// 設定使用者屬性
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
      debugPrint('Analytics error: $e');
    }
  }

  /// 設置 User ID
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// 記錄登入
  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// 記錄註冊
  Future<void> logSignUp({required String signUpMethod}) async {
    try {
      await _analytics.logSignUp(signUpMethod: signUpMethod);
    } catch (e) {
      debugPrint('Analytics error: $e');
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
      debugPrint('Analytics error: $e');
    }
  }

  // Custom events

  /// 記錄配對操作
  Future<void> logMatchAction({
    required String action,
    required String otherUserId,
  }) async {
      await logEvent(name: 'match_action', parameters: {
          'action': action, // like, pass, etc.
          'other_user_id': otherUserId,
      });
  }

  /// 記錄參加活動
  Future<void> logJoinEvent({
    required String eventId,
    String? eventTitle,
  }) async {
      await logEvent(name: 'join_event', parameters: {
          'event_id': eventId,
          if (eventTitle != null) 'event_title': eventTitle,
      });
  }

  /// 記錄發送訊息
  Future<void> logSendMessage({
    required String chatRoomId,
  }) async {
    await logEvent(name: 'send_message', parameters: {
      'chat_room_id': chatRoomId,
    });
  }
}

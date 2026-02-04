import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService? _mockInstance;

  static set mockInstance(AnalyticsService? instance) {
    _mockInstance = instance;
  }

  factory AnalyticsService() {
    return _mockInstance ?? _instance;
  }

  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  /// 記錄一般事件
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('Analytics Event Logged: $name, params: $parameters');
    } catch (e) {
      debugPrint('Analytics Error: $e');
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
      debugPrint('Analytics Screen View: $screenName');
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  /// 記錄登入
  Future<void> logLogin({required String method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      debugPrint('Analytics Login: $method');
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  /// 記錄註冊
  Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      debugPrint('Analytics SignUp: $method');
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  /// 記錄加入活動
  Future<void> logJoinEvent({required String eventId}) async {
    await logEvent(
      name: 'join_event',
      parameters: {'event_id': eventId},
    );
  }

  /// 記錄退出活動
  Future<void> logLeaveEvent({required String eventId}) async {
    await logEvent(
      name: 'leave_event',
      parameters: {'event_id': eventId},
    );
  }

  /// 記錄創建活動
  Future<void> logCreateEvent() async {
    await logEvent(
      name: 'create_event',
    );
  }

  /// 記錄預約活動 (Book Event)
  Future<void> logBookEvent() async {
    await logEvent(
      name: 'book_event',
    );
  }

  /// 記錄配對滑動
  Future<void> logMatchSwipe({
    required bool isLike,
    required bool isMatch,
  }) async {
    await logEvent(
      name: 'swipe',
      parameters: {
        'result': isLike ? 'like' : 'pass',
        'is_match': isMatch ? 'true' : 'false',
      },
    );
  }

  /// 設置用戶屬性
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  /// 設置用戶 ID
  Future<void> setUserId({required String id}) async {
    try {
      await _analytics.setUserId(id: id);
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }
}

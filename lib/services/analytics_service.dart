import 'package:firebase_analytics/firebase_analytics.dart';

/// 用戶行為追蹤服務
/// 集成 Firebase Analytics，追蹤用戶行為（頁面瀏覽、功能使用）
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// 獲取導航觀察者，用於自動追蹤頁面瀏覽
  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// 記錄自定義事件
  ///
  /// [name] 事件名稱 (例如: 'swipe', 'send_message')
  /// [parameters] 事件參數
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters?.cast<String, Object>(),
      );
    } catch (e) {
      // 在開發環境中可以打印錯誤，生產環境通常靜默失敗
      // print('Analytics Log Event Error: $e');
    }
  }

  /// 設置用戶 ID
  ///
  /// 當用戶登入時調用，登出時傳入 null
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
    } catch (e) {
      // print('Analytics Set User ID Error: $e');
    }
  }

  /// 手動記錄頁面瀏覽
  ///
  /// 通常不需要手動調用，因為已配置 Observer 自動追蹤
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
      // print('Analytics Log Screen View Error: $e');
    }
  }

  /// 設置用戶屬性
  ///
  /// 例如: 用戶類型、會員等級等
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      // print('Analytics Set User Property Error: $e');
    }
  }
}

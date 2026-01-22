import 'package:firebase_analytics/firebase_analytics.dart';

/// 封裝 FirebaseAnalytics 以便於測試
class FirebaseAnalyticsWrapper {
  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsWrapper(this._analytics);

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> logLogin({String? loginMethod}) {
    return _analytics.logLogin(loginMethod: loginMethod);
  }

  Future<void> logSignUp({required String signUpMethod}) {
    return _analytics.logSignUp(signUpMethod: signUpMethod);
  }

  Future<void> logScreenView({
    String? screenClass,
    String? screenName,
  }) {
    return _analytics.logScreenView(
      screenClass: screenClass,
      screenName: screenName,
    );
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) {
    return _analytics.setUserProperty(name: name, value: value);
  }

  Future<void> setUserId({String? id}) {
    return _analytics.setUserId(id: id);
  }
}

/// 分析服務 - 負責追蹤用戶行為與數據分析
class AnalyticsService {
  late final FirebaseAnalyticsWrapper _analytics;

  AnalyticsService({FirebaseAnalyticsWrapper? analytics}) {
    _analytics =
        analytics ?? FirebaseAnalyticsWrapper(FirebaseAnalytics.instance);
  }

  /// 記錄自定義事件
  ///
  /// [name] 事件名稱
  /// [parameters] 事件參數
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  /// 記錄螢幕瀏覽
  ///
  /// [screenName] 螢幕名稱
  /// [screenClass] 螢幕類別 (可選)
  Future<void> logScreenView(
    String screenName, {
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  /// 記錄登入事件
  ///
  /// [method] 登入方式 (例如: 'google', 'email')
  Future<void> logLogin({String? method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// 記錄註冊事件
  ///
  /// [method] 註冊方式 (例如: 'google', 'email')
  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  /// 設定用戶屬性
  ///
  /// [name] 屬性名稱
  /// [value] 屬性值
  Future<void> setUserProperty(String name, String? value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// 設定用戶 ID
  ///
  /// [id] 用戶 ID
  Future<void> setUserId(String? id) async {
    await _analytics.setUserId(id: id);
  }
}

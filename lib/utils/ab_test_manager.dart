import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// A/B Testing Manager
/// 支持功能開關和變體測試
class ABTestManager {
  static final ABTestManager _instance = ABTestManager._internal();
  factory ABTestManager() => _instance;
  ABTestManager._internal();

  FirebaseRemoteConfig? _remoteConfigInstance;

  /// 用於測試的 Setter
  @visibleForTesting
  set remoteConfig(FirebaseRemoteConfig config) {
    _remoteConfigInstance = config;
  }

  FirebaseRemoteConfig get _remoteConfig =>
      _remoteConfigInstance ??= FirebaseRemoteConfig.instance;

  /// 初始化 A/B 測試管理器
  /// [defaults] 默認參數配置
  Future<void> initialize({Map<String, dynamic>? defaults}) async {
    try {
      // 設置配置
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        // 在 Debug 模式下設置較短的緩存時間以便快速測試
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 1)
            : const Duration(hours: 12),
      ));

      // 設置默認值
      if (defaults != null) {
        await _remoteConfig.setDefaults(defaults);
      }

      // 獲取並激活
      await fetchAndActivate();

      debugPrint('ABTestManager initialized successfully.');
    } catch (e) {
      debugPrint('Failed to initialize ABTestManager: $e');
    }
  }

  /// 強制獲取並激活最新的配置
  Future<bool> fetchAndActivate() async {
    try {
      final updated = await _remoteConfig.fetchAndActivate();
      if (updated) {
        debugPrint('Remote Config updated.');
      }
      return updated;
    } catch (e) {
      debugPrint('Failed to fetch and activate remote config: $e');
      return false;
    }
  }

  /// 檢查功能開關是否啟用
  /// [key] 參數鍵名
  bool isFeatureEnabled(String key) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      debugPrint('Error getting feature flag $key: $e');
      return false;
    }
  }

  /// 獲取變體值 (String)
  /// [key] 參數鍵名
  String getVariant(String key) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      debugPrint('Error getting variant $key: $e');
      return '';
    }
  }

  /// 獲取數值配置 (Double)
  double getNumber(String key) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      debugPrint('Error getting number $key: $e');
      return 0.0;
    }
  }

  /// 獲取整數配置 (Int)
  int getInt(String key) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      debugPrint('Error getting int $key: $e');
      return 0;
    }
  }

  /// 獲取所有配置 (用於調試)
  Map<String, RemoteConfigValue> getAll() {
    return _remoteConfig.getAll();
  }
}

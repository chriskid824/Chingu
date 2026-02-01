import 'package:firebase_remote_config/firebase_remote_config.dart';

/// A/B Testing Manager
/// 支持功能開關和變體測試 using Firebase Remote Config
class ABTestManager {
  static final ABTestManager _instance = ABTestManager._internal();
  factory ABTestManager() => _instance;
  ABTestManager._internal();

  FirebaseRemoteConfig? _remoteConfig;

  /// Sets the Remote Config instance for testing.
  void setRemoteConfigForTesting(FirebaseRemoteConfig remoteConfig) {
    _remoteConfig = remoteConfig;
  }

  /// Initialize ABTestManager with default values.
  Future<void> initialize() async {
    try {
      _remoteConfig ??= FirebaseRemoteConfig.instance;

      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // 設置默認值
      await _remoteConfig!.setDefaults(const {
        'enable_new_ui': false,
      });

      await _remoteConfig!.fetchAndActivate();
    } catch (e) {
      print('Error initializing Remote Config: $e');
      // Continue with defaults if fetch fails
    }
  }

  /// 檢查功能開關是否啟用
  bool isFeatureEnabled(String key) {
    if (_remoteConfig == null) {
      // 如果尚未初始化，返回默認值 (通常 false，具體取決於用例，這裡保守返回 false)
      return false;
    }
    return _remoteConfig!.getBool(key);
  }

  /// 獲取變體值 (String)
  String getString(String key) {
    if (_remoteConfig == null) {
      return '';
    }
    return _remoteConfig!.getString(key);
  }
}

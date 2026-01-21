import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// A/B Testing Manager
/// Uses Firebase Remote Config to manage feature toggles and A/B test variants.
class ABTestManager {
  static final ABTestManager _instance = ABTestManager._internal();
  factory ABTestManager() => _instance;
  ABTestManager._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Initialize the ABTestManager
  /// [defaults] Optional map of default values for parameters.
  Future<void> initialize({Map<String, dynamic>? defaults}) async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 5)
            : const Duration(hours: 12),
      ));

      if (defaults != null) {
        await _remoteConfig.setDefaults(defaults);
      }

      await _remoteConfig.fetchAndActivate();
      debugPrint('ABTestManager initialized and config activated.');
    } catch (e) {
      debugPrint('Failed to initialize ABTestManager: $e');
      // In case of error, the app will continue using defaults (if set) or cached values.
    }
  }

  /// Check if a feature is enabled (boolean toggle).
  bool isFeatureEnabled(String key) {
    return _remoteConfig.getBool(key);
  }

  /// Get the variant for a given test (string value).
  /// Useful for A/B tests where variants are named (e.g. "control", "variant_a").
  String getVariant(String key) {
    return _remoteConfig.getString(key);
  }

  /// Get a string value from Remote Config.
  String getString(String key) {
    return _remoteConfig.getString(key);
  }

  /// Get a number value (double) from Remote Config.
  double getNumber(String key) {
    return _remoteConfig.getDouble(key);
  }

  /// Get a boolean value from Remote Config.
  bool getBool(String key) {
    return _remoteConfig.getBool(key);
  }

  /// Force fetch and activate (e.g. for debugging or manual refresh).
  Future<bool> refresh() async {
    try {
      return await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('Failed to refresh ABTestManager: $e');
      return false;
    }
  }
}

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// A/B Testing Manager
/// Handles Feature Flags and A/B Testing variants using Firebase Remote Config.
class ABTestManager {
  static final ABTestManager _instance = ABTestManager._internal();
  factory ABTestManager() => _instance;
  ABTestManager._internal();

  FirebaseRemoteConfig? _testRemoteConfig;
  FirebaseRemoteConfig get _remoteConfig => _testRemoteConfig ?? FirebaseRemoteConfig.instance;

  @visibleForTesting
  void setRemoteConfigForTesting(FirebaseRemoteConfig remoteConfig) {
    _testRemoteConfig = remoteConfig;
  }

  /// Initialize Remote Config with default values and settings.
  ///
  /// [defaults] A map of default values to use before fetching from the cloud.
  Future<void> initialize({Map<String, dynamic>? defaults}) async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 5) // Frequent fetches in debug
            : const Duration(hours: 12), // Cache for 12 hours in prod
      ));

      if (defaults != null) {
        await _remoteConfig.setDefaults(defaults);
      }

      // Fetch and activate immediately on startup to get latest config
      // Note: In a real app, you might want to wait or use a loading screen,
      // or just accept that the first session uses defaults/cached values.
      await fetchAndActivate();

      if (kDebugMode) {
        print('[ABTestManager] Initialized. Last fetch status: ${_remoteConfig.lastFetchStatus}');
      }
    } catch (e) {
      print('[ABTestManager] Initialization failed: $e');
    }
  }

  /// Fetch and activate latest values from the cloud.
  /// Returns true if configs were updated.
  Future<bool> fetchAndActivate() async {
    try {
      bool updated = await _remoteConfig.fetchAndActivate();
      if (kDebugMode) {
        print('[ABTestManager] Fetch and activate: $updated');
      }
      return updated;
    } catch (e) {
      print('[ABTestManager] Fetch failed: $e');
      return false;
    }
  }

  /// Check if a feature flag is enabled (boolean).
  bool isFeatureEnabled(String key) {
    return _remoteConfig.getBool(key);
  }

  /// Get a string value (e.g. for variant names like "variant_a").
  String getString(String key) {
    return _remoteConfig.getString(key);
  }

  /// Get a number value.
  double getNumber(String key) {
    return _remoteConfig.getDouble(key);
  }

  /// Get a boolean value directly.
  bool getBool(String key) {
    return _remoteConfig.getBool(key);
  }

  /// Get all current values (useful for debugging).
  Map<String, RemoteConfigValue> getAllValues() {
    return _remoteConfig.getAll();
  }
}

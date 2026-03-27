import 'package:flutter/foundation.dart';

/// A utility class for managing A/B tests and feature toggles.
class ABTestManager {
  static final ABTestManager _instance = ABTestManager._internal();

  factory ABTestManager() {
    return _instance;
  }

  ABTestManager._internal();

  String? _userId;

  /// Initializes the manager with the current user ID.
  /// This should be called when the user logs in or the app starts with a logged-in user.
  void initialize(String userId) {
    _userId = userId;
    debugPrint('ABTestManager initialized for user: $userId');
  }

  /// Clears the user ID, effectively resetting to default behaviors.
  void reset() {
    _userId = null;
  }

  /// Local overrides for feature toggles (useful for development/testing)
  final Map<String, bool> _featureOverrides = {};

  /// Sets a local override for a feature toggle.
  void setFeatureOverride(String featureKey, bool isEnabled) {
    _featureOverrides[featureKey] = isEnabled;
  }

  /// Clears all feature overrides.
  void clearFeatureOverrides() {
    _featureOverrides.clear();
  }

  /// Checks if a feature is enabled.
  ///
  /// [featureKey]: Unique identifier for the feature.
  /// [rolloutPercentage]: Percentage of users (0-100) who should see this feature.
  /// [defaultValue]: Value to return if user is not logged in (unless rollout is 100).
  bool isFeatureEnabled(
    String featureKey, {
    int rolloutPercentage = 0,
    bool defaultValue = false,
  }) {
    if (_featureOverrides.containsKey(featureKey)) {
      return _featureOverrides[featureKey]!;
    }

    if (rolloutPercentage >= 100) return true;
    if (rolloutPercentage <= 0) return false;

    if (_userId == null) {
      return defaultValue;
    }

    // Create a stable hash based on user ID and feature key
    final hash = _getStableHash('$_userId-$featureKey');
    // Normalize to 0-99
    final normalizedHash = hash.abs() % 100;

    return normalizedHash < rolloutPercentage;
  }

  /// Returns the variant for a given experiment.
  ///
  /// [experimentKey]: Unique identifier for the experiment.
  /// [variants]: List of possible variant values (e.g., ['A', 'B', 'C']).
  /// [defaultVariant]: Variant to return if user is not logged in. If null, first variant is used.
  T getVariant<T>(
    String experimentKey,
    List<T> variants, {
    T? defaultVariant,
  }) {
    if (variants.isEmpty) {
      throw ArgumentError('Variants list cannot be empty');
    }

    if (_userId == null) {
      return defaultVariant ?? variants.first;
    }

    // Create a stable hash based on user ID and experiment key
    final hash = _getStableHash('$_userId-$experimentKey');
    final index = hash.abs() % variants.length;

    return variants[index];
  }

  /// Generates a stable hash code for a string that persists across app restarts.
  /// Standard Dart String.hashCode is not guaranteed to be stable across runs.
  int _getStableHash(String value) {
    int hash = 0;
    for (int i = 0; i < value.length; i++) {
      // 31 is a standard prime for hashing
      hash = (31 * hash + value.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash;
  }
}

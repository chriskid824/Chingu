/// A singleton utility for A/B testing and feature toggles.
///
/// It uses a deterministic hash of [userId] and [experimentId] to assign
/// variants consistently on the client side without immediate backend persistence.
class ABTestManager {
  static final ABTestManager _instance = ABTestManager._internal();

  factory ABTestManager() {
    return _instance;
  }

  ABTestManager._internal();

  String? _userId;

  // Allow overrides for testing or specific QA scenarios
  final Map<String, bool> _featureOverrides = {};
  final Map<String, String> _variantOverrides = {};

  /// Initialize with the current user ID.
  /// This should be called as soon as the user is authenticated.
  void initialize(String userId) {
    _userId = userId;
  }

  /// Returns true if the feature is enabled for the current user.
  ///
  /// [featureKey]: The unique key for the feature toggle.
  /// [defaultValue]: The value to return if the user is not logged in or an error occurs.
  /// [trafficAllocation]: A value between 0.0 and 1.0 representing the percentage of users
  /// who should have this feature enabled (e.g., 0.5 for 50%).
  bool isFeatureEnabled(
    String featureKey, {
    bool defaultValue = false,
    double trafficAllocation = 0.5,
  }) {
    if (_featureOverrides.containsKey(featureKey)) {
      return _featureOverrides[featureKey]!;
    }

    if (_userId == null) {
      return defaultValue;
    }

    final hash = _getHash('$_userId:$featureKey');
    final normalized = _normalizeHash(hash);

    return normalized < trafficAllocation;
  }

  /// Returns the assigned variant for the experiment.
  ///
  /// [experimentId]: The unique ID for the experiment.
  /// [variants]: A list of variant names (e.g., ['control', 'variant_a']).
  /// [weights]: Optional weights for each variant. If provided, must sum to 1.0 and match [variants] length.
  ///
  /// Returns the first variant if no user is logged in.
  String getVariant(
    String experimentId,
    List<String> variants, {
    List<double>? weights,
  }) {
    if (variants.isEmpty) {
      throw ArgumentError('Variants cannot be empty');
    }

    if (_variantOverrides.containsKey(experimentId)) {
      return _variantOverrides[experimentId]!;
    }

    if (_userId == null) {
      return variants.first; // Default to control/first variant
    }

    if (weights != null) {
      if (weights.length != variants.length) {
        throw ArgumentError('Weights length must match variants length');
      }

      // Check sum roughly 1.0, but we proceed with logic as is
    }

    final hash = _getHash('$_userId:$experimentId');
    final normalized = _normalizeHash(hash);

    if (weights == null) {
      // Equal distribution
      final step = 1.0 / variants.length;
      int index = (normalized / step).floor();
      if (index >= variants.length) index = variants.length - 1;
      return variants[index];
    } else {
      // Weighted distribution
      double cumulative = 0.0;
      for (int i = 0; i < weights.length; i++) {
        cumulative += weights[i];
        if (normalized < cumulative) {
          return variants[i];
        }
      }
      return variants.last;
    }
  }

  /// DJB2 hash implementation for consistent hashing across platforms.
  int _getHash(String input) {
    int hash = 5381;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) + hash) + input.codeUnitAt(i); /* hash * 33 + c */
      // Force to 32-bit integer range to ensure consistency
      hash = hash & 0xFFFFFFFF;
    }
    return hash;
  }

  /// Normalizes the hash to a value between 0.0 and 1.0.
  double _normalizeHash(int hash) {
    // Use the absolute value and mod 10000 for 4 decimal precision
    return (hash.abs() % 10000) / 10000.0;
  }

  // -- Debug / QA helpers --

  void setFeatureOverride(String featureKey, bool isEnabled) {
    _featureOverrides[featureKey] = isEnabled;
  }

  void setVariantOverride(String experimentId, String variant) {
    _variantOverrides[experimentId] = variant;
  }

  void clearOverrides() {
    _featureOverrides.clear();
    _variantOverrides.clear();
  }

  /// Resets the manager state (clears user and overrides).
  void reset() {
    _userId = null;
    clearOverrides();
  }
}

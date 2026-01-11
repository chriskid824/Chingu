
class ABTestManager {
  // Singleton instance
  static final ABTestManager _instance = ABTestManager._internal();

  factory ABTestManager() => _instance;

  ABTestManager._internal();

  String? _userId;
  final Map<String, dynamic> _overrides = {};

  /// Initializes the manager with the current user ID.
  /// This should be called once the user is authenticated.
  void initialize(String userId) {
    _userId = userId;
  }

  /// Sets a local override for a specific feature or experiment key.
  /// Useful for testing or forcing specific variants.
  void setOverride(String key, dynamic value) {
    _overrides[key] = value;
  }

  /// Removes a local override.
  void clearOverride(String key) {
    _overrides.remove(key);
  }

  /// Checks if a feature is enabled based on traffic allocation.
  ///
  /// [featureKey] Unique identifier for the feature.
  /// [traffic] Percentage of users who should see this feature (0.0 to 1.0).
  ///
  /// Returns true if the feature is enabled for this user.
  bool isFeatureEnabled(String featureKey, {double traffic = 1.0}) {
    if (_overrides.containsKey(featureKey)) {
      return _overrides[featureKey] as bool;
    }

    if (_userId == null) {
      return false;
    }

    // Generate a hash based on user ID and feature key
    final hash = _djb2('$_userId:$featureKey');

    // Normalize to 0-99 range
    final normalized = hash.abs() % 100;

    // Check if within traffic range (e.g., traffic 0.5 means 0-49)
    return normalized < (traffic * 100);
  }

  /// Determines which variant a user belongs to in an experiment.
  ///
  /// [experimentKey] Unique identifier for the experiment.
  /// [variants] Map of variant names to their weights (e.g., {'A': 50, 'B': 50}).
  /// [defaultVariant] Fallback variant if something goes wrong.
  ///
  /// Returns the selected variant name.
  String getVariant(String experimentKey, Map<String, int> variants, {String defaultVariant = 'control'}) {
    if (_overrides.containsKey(experimentKey)) {
      return _overrides[experimentKey] as String;
    }

    if (_userId == null || variants.isEmpty) {
      return defaultVariant;
    }

    final totalWeight = variants.values.fold(0, (sum, weight) => sum + weight);
    if (totalWeight <= 0) return defaultVariant;

    final hash = _djb2('$_userId:$experimentKey');
    final normalized = hash.abs() % totalWeight;

    int currentWeight = 0;
    for (final entry in variants.entries) {
      currentWeight += entry.value;
      if (normalized < currentWeight) {
        return entry.key;
      }
    }

    return defaultVariant;
  }

  /// DJB2 Hash Algorithm
  /// A simple, deterministic string hash function.
  int _djb2(String s) {
    int hash = 5381;
    for (int i = 0; i < s.length; i++) {
      // hash * 33 + c
      hash = ((hash << 5) + hash) + s.codeUnitAt(i);
    }
    return hash;
  }
}

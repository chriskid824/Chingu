
class ABTestManager {
  static final ABTestManager _instance = ABTestManager._internal();

  factory ABTestManager() {
    return _instance;
  }

  ABTestManager._internal();

  Map<String, dynamic> _config = {};

  /// Initialize the manager with a configuration map.
  /// This map can come from a remote source (e.g. Firebase Remote Config) or a local file.
  void initialize(Map<String, dynamic> config) {
    _config = config;
  }

  /// Check if a feature is enabled.
  ///
  /// [featureKey] The key of the feature flag.
  /// [defaultValue] The value to return if the key is not found.
  bool isFeatureEnabled(String featureKey, {bool defaultValue = false}) {
    if (_config.containsKey(featureKey)) {
      final value = _config[featureKey];
      if (value is bool) {
        return value;
      }
      // Handle cases where the value might be a string "true"/"false" from remote config
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
    }
    return defaultValue;
  }

  /// Get the variant for a user in a specific experiment.
  ///
  /// [experimentKey] The key of the experiment.
  /// [userId] The ID of the user.
  /// [variants] List of variant names (e.g. ['A', 'B']).
  /// [weights] List of weights corresponding to variants (e.g. [0.5, 0.5]).
  ///           Sum should ideally be 1.0, but we will normalize it.
  String getVariant(
    String experimentKey,
    String userId, {
    List<String> variants = const ['control', 'variant'],
    List<double> weights = const [0.5, 0.5],
  }) {
    if (variants.length != weights.length) {
      throw ArgumentError('Variants and weights must have the same length');
    }

    if (variants.isEmpty) {
      throw ArgumentError('Variants cannot be empty');
    }

    // Check if there is an explicit override in the config
    // e.g. "experiment_color_btn": "blue" (forcing a variant globally)
    if (_config.containsKey(experimentKey)) {
      final configValue = _config[experimentKey];
      if (configValue is String && variants.contains(configValue)) {
        return configValue;
      }
    }

    // Deterministic hash
    // We combine userId and experimentKey to ensure independence between experiments
    final String key = '$userId:$experimentKey';
    final int hash = _stableHash(key);

    // Normalize hash to 0.0 - 1.0 range
    // We use a large modulus for better distribution
    final double normalizedHash = (hash.abs() % 10000) / 10000.0;

    double cumulativeWeight = 0.0;
    double totalWeight = weights.reduce((a, b) => a + b);

    for (int i = 0; i < variants.length; i++) {
      cumulativeWeight += weights[i] / totalWeight;
      if (normalizedHash < cumulativeWeight) {
        return variants[i];
      }
    }

    return variants.last;
  }

  /// A stable hash function (DJB2) to ensure consistent results across platforms/runs.
  int _stableHash(String str) {
    int hash = 5381;
    for (int i = 0; i < str.length; i++) {
      hash = ((hash << 5) + hash) + str.codeUnitAt(i); /* hash * 33 + c */
      hash = hash & 0xFFFFFFFF; // Ensure 32-bit integer behavior
    }
    return hash;
  }
}

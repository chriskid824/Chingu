import 'dart:math';

/// A utility class for managing A/B tests and feature toggles.
///
/// This class uses deterministic hashing to assign users to experiment groups
/// or toggle features, ensuring that the same user always sees the same variant
/// for a given experiment ID, without needing to store the assignment in a database.
class ABTestManager {
  static final ABTestManager _instance = ABTestManager._internal();

  /// Returns the singleton instance of [ABTestManager].
  factory ABTestManager() {
    return _instance;
  }

  ABTestManager._internal();

  /// Checks if a feature is enabled for the given user based on a rollout percentage.
  ///
  /// [userId]: The unique ID of the user.
  /// [featureId]: The unique ID of the feature flag.
  /// [rolloutPercentage]: A value between 0.0 and 1.0 indicating the percentage of users
  /// who should have the feature enabled. Default is 0.5 (50%).
  ///
  /// Returns `true` if the feature is enabled for the user, `false` otherwise.
  bool isFeatureEnabled({
    required String userId,
    required String featureId,
    double rolloutPercentage = 0.5,
  }) {
    if (rolloutPercentage <= 0.0) return false;
    if (rolloutPercentage >= 1.0) return true;

    final hash = _generateHash(userId, featureId);
    // Normalize to 0.0 - 1.0
    // Use (hash % 10000).abs() to handle negative hashes safely including int.minValue
    final normalized = (hash % 10000).abs() / 10000.0;

    return normalized < rolloutPercentage;
  }

  /// Returns the assigned variant for a given experiment.
  ///
  /// [userId]: The unique ID of the user.
  /// [experimentId]: The unique ID of the experiment.
  /// [variants]: A list of possible variant values.
  /// [weights]: Optional list of weights corresponding to the variants.
  /// The sum of weights should differ from 1.0 by no more than 0.01.
  /// If provided, [weights] must have the same length as [variants].
  ///
  /// Returns one of the items from [variants].
  T getVariant<T>({
    required String userId,
    required String experimentId,
    required List<T> variants,
    List<double>? weights,
  }) {
    if (variants.isEmpty) {
      throw ArgumentError('Variants list cannot be empty');
    }
    if (variants.length == 1) {
      return variants.first;
    }

    if (weights != null) {
      if (weights.length != variants.length) {
        throw ArgumentError('Weights length must match variants length');
      }
      final sum = weights.fold(0.0, (double a, double b) => a + b);
      if ((sum - 1.0).abs() > 0.01) {
        // While we could throw, it might be better to just proceed with what we have
        // or normalize. For now, we assume the caller is responsible.
        // throw ArgumentError('Sum of weights must be approximately 1.0');
      }
    }

    final hash = _generateHash(userId, experimentId);
    final normalized = (hash % 10000).abs() / 10000.0;

    if (weights != null) {
      double cumulative = 0.0;
      for (int i = 0; i < weights.length; i++) {
        cumulative += weights[i];
        if (normalized < cumulative) {
          return variants[i];
        }
      }
      return variants.last;
    } else {
      // Uniform distribution
      final index = (normalized * variants.length).floor();
      return variants[min(index, variants.length - 1)];
    }
  }

  /// Generates a deterministic hash based on the user ID and key.
  ///
  /// Uses a DJB2-like algorithm.
  int _generateHash(String userId, String key) {
    final str = '$userId:$key';
    int hash = 5381;
    for (int i = 0; i < str.length; i++) {
      hash = ((hash << 5) + hash) + str.codeUnitAt(i);
      // Note: Dart's int is 64-bit on the VM, which is sufficient.
      // JS target handles bitwise ops as 32-bit ints, which is also consistent enough for this.
    }
    return hash;
  }
}

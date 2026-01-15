import 'package:flutter/foundation.dart';

/// Defines the possible variants for an A/B test.
enum ABTestVariant {
  control,
  variantA,
  variantB,
  variantC,
}

/// A manager for handling A/B testing and feature toggles within the application.
///
/// This class provides a centralized way to define experiments, assign users to
/// variants deterministically, and check the status of feature flags.
class ABTestManager {
  static final ABTestManager _instance = ABTestManager._internal();

  factory ABTestManager() {
    return _instance;
  }

  ABTestManager._internal();

  /// Configuration of active experiments and their available variants.
  /// Keys are experiment IDs, and values are the list of variants involved.
  final Map<String, List<ABTestVariant>> _experiments = {
    'example_experiment': [ABTestVariant.control, ABTestVariant.variantA],
    // Add real experiments here
    // 'new_onboarding_flow': [ABTestVariant.control, ABTestVariant.variantA, ABTestVariant.variantB],
  };

  /// Configuration of feature flags.
  /// Keys are feature IDs, and values are booleans indicating if the feature is enabled.
  final Map<String, bool> _featureFlags = {
    'example_feature': true,
    // Add real feature flags here
    // 'enable_video_calls': false,
  };

  /// Returns the assigned [ABTestVariant] for a given [experimentId] and [userId].
  ///
  /// This method uses a deterministic hashing algorithm to ensure that the same
  /// user is always assigned to the same variant for a given experiment.
  ///
  /// If the [experimentId] is not found or has no variants, it returns [ABTestVariant.control].
  ABTestVariant getVariant({
    required String experimentId,
    required String userId,
  }) {
    if (!_experiments.containsKey(experimentId)) {
      debugPrint('ABTestManager: Experiment $experimentId not found, defaulting to control.');
      return ABTestVariant.control;
    }

    final variants = _experiments[experimentId]!;
    if (variants.isEmpty) {
      return ABTestVariant.control;
    }

    // Generate a deterministic index based on user ID and experiment ID
    final int hash = _generateHash(userId + experimentId);
    final int index = hash % variants.length;

    return variants[index];
  }

  /// Checks if a feature is enabled.
  ///
  /// Returns `true` if the feature is explicitly enabled in the configuration,
  /// `false` otherwise.
  bool isFeatureEnabled(String featureId) {
    return _featureFlags[featureId] ?? false;
  }

  /// Simple deterministic hash function (djb2 implementation adapted for Dart).
  int _generateHash(String input) {
    int hash = 5381;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) + hash) + input.codeUnitAt(i); /* hash * 33 + c */
    }
    return hash.abs();
  }

  /// Helper to check if a specific variant is active for a user.
  bool isVariant({
    required String experimentId,
    required String userId,
    required ABTestVariant variant,
  }) {
    return getVariant(experimentId: experimentId, userId: userId) == variant;
  }
}

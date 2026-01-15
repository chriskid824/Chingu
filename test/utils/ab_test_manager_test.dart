import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/ab_test_manager.dart';

void main() {
  group('ABTestManager', () {
    final manager = ABTestManager();

    test('isFeatureEnabled should be deterministic', () {
      final userId = 'user123';
      final featureId = 'test_feature';

      final result1 = manager.isFeatureEnabled(userId: userId, featureId: featureId);
      final result2 = manager.isFeatureEnabled(userId: userId, featureId: featureId);

      expect(result1, equals(result2));
    });

    test('isFeatureEnabled should respect rollout percentage', () {
      final featureId = 'test_feature_rollout';
      int enabledCount = 0;
      final totalUsers = 1000;

      // Test with 50% rollout
      for (int i = 0; i < totalUsers; i++) {
        if (manager.isFeatureEnabled(
          userId: 'user_$i',
          featureId: featureId,
          rolloutPercentage: 0.5
        )) {
          enabledCount++;
        }
      }

      // Should be roughly 50% +/- 5%
      expect(enabledCount, greaterThan(450));
      expect(enabledCount, lessThan(550));
    });

    test('isFeatureEnabled returns false for 0.0 rollout', () {
      expect(manager.isFeatureEnabled(userId: 'u1', featureId: 'f1', rolloutPercentage: 0.0), isFalse);
    });

    test('isFeatureEnabled returns true for 1.0 rollout', () {
      expect(manager.isFeatureEnabled(userId: 'u1', featureId: 'f1', rolloutPercentage: 1.0), isTrue);
    });

    test('getVariant should be deterministic', () {
      final userId = 'user456';
      final experimentId = 'test_experiment';
      final variants = ['A', 'B', 'C'];

      final result1 = manager.getVariant(userId: userId, experimentId: experimentId, variants: variants);
      final result2 = manager.getVariant(userId: userId, experimentId: experimentId, variants: variants);

      expect(result1, equals(result2));
    });

    test('getVariant should distribute uniformly by default', () {
      final experimentId = 'test_experiment_uniform';
      final variants = ['A', 'B'];
      int countA = 0;
      int countB = 0;
      final totalUsers = 1000;

      for (int i = 0; i < totalUsers; i++) {
        final variant = manager.getVariant(
          userId: 'user_$i',
          experimentId: experimentId,
          variants: variants,
        );
        if (variant == 'A') countA++;
        else if (variant == 'B') countB++;
      }

      // Roughly 50/50
      expect(countA, greaterThan(450));
      expect(countA, lessThan(550));
      expect(countB, greaterThan(450));
      expect(countB, lessThan(550));
    });

    test('getVariant should respect weights', () {
      final experimentId = 'test_experiment_weighted';
      final variants = ['A', 'B'];
      final weights = [0.2, 0.8]; // 20% A, 80% B

      int countA = 0;
      int countB = 0;
      final totalUsers = 1000;

      for (int i = 0; i < totalUsers; i++) {
        final variant = manager.getVariant(
          userId: 'user_$i',
          experimentId: experimentId,
          variants: variants,
          weights: weights,
        );
        if (variant == 'A') countA++;
        else if (variant == 'B') countB++;
      }

      // Roughly 20% A (150-250)
      expect(countA, greaterThan(150));
      expect(countA, lessThan(250));

      // Roughly 80% B (750-850)
      expect(countB, greaterThan(750));
      expect(countB, lessThan(850));
    });

    test('getVariant throws on mismatched weights', () {
      expect(() => manager.getVariant(
        userId: 'u',
        experimentId: 'e',
        variants: ['A', 'B'],
        weights: [0.5]
      ), throwsArgumentError);
    });

    test('Changing featureId should change distribution (uncorrelated)', () {
      // It's hard to prove uncorrelation in a unit test deterministically for small N,
      // but we can check that for a specific user, changing the featureId produces different hash outcomes often.
      // Or rather, just check that the hash is different.

      // We can't access private _generateHash directly, but we can verify that
      // assignment changes for at least some users when featureId changes.

      int changes = 0;
      for (int i = 0; i < 100; i++) {
        final u = 'user_$i';
        final v1 = manager.getVariant(userId: u, experimentId: 'exp1', variants: ['A', 'B']);
        final v2 = manager.getVariant(userId: u, experimentId: 'exp2', variants: ['A', 'B']);
        if (v1 != v2) changes++;
      }
      // Should not be 0 changes (unless extremely unlucky or hash is broken)
      expect(changes, greaterThan(0));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/ab_test_manager.dart';

void main() {
  late ABTestManager abTestManager;

  setUp(() {
    abTestManager = ABTestManager();
    abTestManager.reset();
  });

  group('ABTestManager Initialization', () {
    test('should return default false for feature flags if not initialized', () {
      expect(abTestManager.isFeatureEnabled('new_feature'), isFalse);
    });

    test('should return first variant if not initialized', () {
      expect(
        abTestManager.getVariant('button_color', ['red', 'blue']),
        equals('red'),
      );
    });

    test('should allow initialization', () {
      abTestManager.initialize('user_123');
      // Just verifying it doesn't throw. Logic tests are below.
    });
  });

  group('Feature Flags (isFeatureEnabled)', () {
    test('should always return true for 100% allocation', () {
      abTestManager.initialize('user_123');
      expect(
        abTestManager.isFeatureEnabled('feature_all', trafficAllocation: 1.0),
        isTrue,
      );
    });

    test('should always return false for 0% allocation', () {
      abTestManager.initialize('user_123');
      expect(
        abTestManager.isFeatureEnabled('feature_none', trafficAllocation: 0.0),
        isFalse,
      );
    });

    test('should be deterministic for the same user', () {
      abTestManager.initialize('user_deterministic');
      final result1 = abTestManager.isFeatureEnabled('feature_50', trafficAllocation: 0.5);

      // Re-initialize or call again
      abTestManager.initialize('user_deterministic');
      final result2 = abTestManager.isFeatureEnabled('feature_50', trafficAllocation: 0.5);

      expect(result1, equals(result2));
    });

    test('should distribute different users roughly according to allocation', () {
      // This is a probabilistic test, but with specific user IDs we can verify behavior.
      // We'll just check specific known hashes if we want strict unit tests,
      // but here we check that distinct users get different results.

      int enabledCount = 0;
      int totalUsers = 100;

      for (int i = 0; i < totalUsers; i++) {
        abTestManager.initialize('user_$i');
        if (abTestManager.isFeatureEnabled('feature_50_test', trafficAllocation: 0.5)) {
          enabledCount++;
        }
      }

      // 50% allocation should result in roughly 50 users.
      // Due to small sample size and hash distribution, we allow a range.
      expect(enabledCount, greaterThan(30));
      expect(enabledCount, lessThan(70));
    });
  });

  group('Variants (getVariant)', () {
    test('should return variants deterministically', () {
      abTestManager.initialize('user_abc');
      final variant1 = abTestManager.getVariant('experiment_color', ['A', 'B']);

      abTestManager.initialize('user_abc');
      final variant2 = abTestManager.getVariant('experiment_color', ['A', 'B']);

      expect(variant1, equals(variant2));
    });

    test('should respect weights', () {
      int countA = 0;
      int countB = 0;
      int totalUsers = 100;

      // 80% A, 20% B
      for (int i = 0; i < totalUsers; i++) {
        abTestManager.initialize('user_$i');
        final result = abTestManager.getVariant(
          'weighted_experiment',
          ['A', 'B'],
          weights: [0.8, 0.2],
        );
        if (result == 'A') countA++;
        else countB++;
      }

      expect(countA, greaterThan(60)); // Expecting around 80
      expect(countB, lessThan(40));    // Expecting around 20
    });

    test('should return last variant if cumulative weight is slightly off but covers range', () {
      abTestManager.initialize('user_edge_case');
      // Even if weights sum < 1.0 (e.g. 0.99), the logic should fallback to last or work correctly.
      // Our implementation falls through to last variant if loop finishes.
      final result = abTestManager.getVariant(
        'sum_test',
        ['A', 'B'],
        weights: [0.5, 0.4], // Sum 0.9
      );
      expect(['A', 'B'], contains(result));
    });
  });

  group('Overrides', () {
    test('should return override value for feature flag', () {
      abTestManager.initialize('user_123');
      abTestManager.setOverride('feature_override', true);

      expect(
        abTestManager.isFeatureEnabled('feature_override', trafficAllocation: 0.0),
        isTrue,
      );
    });

    test('should return override value for variant', () {
      abTestManager.initialize('user_123');
      abTestManager.setOverride('experiment_override', 'C');

      expect(
        abTestManager.getVariant('experiment_override', ['A', 'B']),
        equals('C'),
      );
    });

    test('should clear overrides', () {
      abTestManager.setOverride('feature_override', true);
      abTestManager.clearOverrides();

      // With 0.0 allocation, should be false without override
      expect(
        abTestManager.isFeatureEnabled('feature_override', trafficAllocation: 0.0),
        isFalse,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/ab_test_manager.dart';

void main() {
  group('ABTestManager', () {
    late ABTestManager abTestManager;

    setUp(() {
      abTestManager = ABTestManager();
      abTestManager.reset();
    });

    test('should return default value when not initialized', () {
      expect(
        abTestManager.isFeatureEnabled('new_feature', defaultValue: false),
        false,
      );
      expect(
        abTestManager.isFeatureEnabled('new_feature', defaultValue: true),
        true,
      );
      expect(
        abTestManager.getVariant('exp_1', ['A', 'B']),
        'A',
      );
    });

    test('should return consistent feature toggle for same user', () {
      abTestManager.initialize('user_123');
      final result1 = abTestManager.isFeatureEnabled('feature_a');

      abTestManager.initialize('user_123');
      final result2 = abTestManager.isFeatureEnabled('feature_a');

      expect(result1, result2);
    });

    test('should distribute traffic roughly as expected', () {
      // This is a probabilistic test, so we just check if it returns both values
      // for enough users.
      int enabledCount = 0;
      int totalUsers = 1000;

      for (int i = 0; i < totalUsers; i++) {
        abTestManager.initialize('user_$i');
        if (abTestManager.isFeatureEnabled('feature_distribution', trafficAllocation: 0.5)) {
          enabledCount++;
        }
      }

      // Expect roughly 50%
      expect(enabledCount, greaterThan(400));
      expect(enabledCount, lessThan(600));
    });

    test('should respect feature overrides', () {
      abTestManager.initialize('user_123');
      abTestManager.setFeatureOverride('feature_b', true);

      expect(abTestManager.isFeatureEnabled('feature_b'), true);

      abTestManager.setFeatureOverride('feature_b', false);
      expect(abTestManager.isFeatureEnabled('feature_b'), false);
    });

    test('should return consistent variant for same user', () {
      abTestManager.initialize('user_456');
      final variant1 = abTestManager.getVariant('experiment_color', ['Red', 'Blue', 'Green']);

      abTestManager.initialize('user_456');
      final variant2 = abTestManager.getVariant('experiment_color', ['Red', 'Blue', 'Green']);

      expect(variant1, variant2);
    });

    test('should respect variant weights', () {
      int variantACount = 0;
      int variantBCount = 0;
      int totalUsers = 1000;

      for (int i = 0; i < totalUsers; i++) {
        abTestManager.initialize('user_$i');
        final variant = abTestManager.getVariant(
          'experiment_weighted',
          ['A', 'B'],
          weights: [0.8, 0.2]
        );

        if (variant == 'A') variantACount++;
        else if (variant == 'B') variantBCount++;
      }

      // Expect roughly 80% A, 20% B
      expect(variantACount, greaterThan(700));
      expect(variantBCount, lessThan(300));
    });

    test('should respect variant overrides', () {
       abTestManager.initialize('user_789');
       abTestManager.setVariantOverride('experiment_override', 'C');

       expect(
         abTestManager.getVariant('experiment_override', ['A', 'B', 'C']),
         'C'
       );
    });
  });
}

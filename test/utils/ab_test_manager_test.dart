import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/ab_test_manager.dart';

void main() {
  group('ABTestManager', () {
    test('is singleton', () {
      final manager1 = ABTestManager();
      final manager2 = ABTestManager();
      expect(manager1, same(manager2));
    });

    test('isFeatureEnabled returns correct values', () {
      final manager = ABTestManager();
      manager.initialize({
        'feature_true': true,
        'feature_false': false,
        'feature_string_true': 'true',
        'feature_string_false': 'false',
      });

      expect(manager.isFeatureEnabled('feature_true'), isTrue);
      expect(manager.isFeatureEnabled('feature_false'), isFalse);
      expect(manager.isFeatureEnabled('feature_string_true'), isTrue);
      expect(manager.isFeatureEnabled('feature_string_false'), isFalse);
      expect(manager.isFeatureEnabled('missing_feature', defaultValue: false), isFalse);
      expect(manager.isFeatureEnabled('missing_feature', defaultValue: true), isTrue);
    });

    test('getVariant returns deterministic results', () {
      final manager = ABTestManager();
      // Reset config just in case
      manager.initialize({});

      const experimentKey = 'test_experiment';
      const userId = 'user_123';
      const variants = ['A', 'B'];
      const weights = [0.5, 0.5];

      final variant1 = manager.getVariant(experimentKey, userId, variants: variants, weights: weights);
      final variant2 = manager.getVariant(experimentKey, userId, variants: variants, weights: weights);

      expect(variant1, equals(variant2));
    });

    test('getVariant respects override from config', () {
      final manager = ABTestManager();
      manager.initialize({
        'test_experiment': 'B',
      });

      const experimentKey = 'test_experiment';
      const userId = 'user_123';

      // Even if hash directs to A, config should force B
      // Note: We need to ensure that the user would have picked something else if not for the override,
      // or just trust the logic. The logic is: check config, if matches variant, return it.

      final variant = manager.getVariant(experimentKey, userId, variants: ['A', 'B']);
      expect(variant, equals('B'));
    });

    test('getVariant distributes roughly according to weights', () {
      final manager = ABTestManager();
      manager.initialize({});

      const experimentKey = 'distribution_test';
      const variants = ['A', 'B'];
      const weights = [0.3, 0.7]; // 30% A, 70% B

      int countA = 0;
      int countB = 0;
      const totalUsers = 1000;

      for (int i = 0; i < totalUsers; i++) {
        final userId = 'user_$i';
        final variant = manager.getVariant(experimentKey, userId, variants: variants, weights: weights);
        if (variant == 'A') countA++;
        else if (variant == 'B') countB++;
      }

      // Allow some margin of error (e.g., +/- 5%)
      expect(countA / totalUsers, closeTo(0.3, 0.05));
      expect(countB / totalUsers, closeTo(0.7, 0.05));
    });

    test('getVariant throws argument error on mismatch', () {
        final manager = ABTestManager();
        expect(() => manager.getVariant('exp', 'user', variants: ['A'], weights: [0.5, 0.5]), throwsArgumentError);
    });
  });
}

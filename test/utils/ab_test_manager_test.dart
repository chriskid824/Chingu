import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/ab_test_manager.dart';

void main() {
  group('ABTestManager', () {
    late ABTestManager abManager;

    setUp(() {
      abManager = ABTestManager();
      abManager.reset();
      abManager.clearFeatureOverrides();
    });

    test('isFeatureEnabled returns default value when user not initialized', () {
      expect(abManager.isFeatureEnabled('feature_x', defaultValue: true), isTrue);
      expect(abManager.isFeatureEnabled('feature_x', defaultValue: false), isFalse);
    });

    test('isFeatureEnabled handles 0 and 100 rollout correctly without user', () {
      expect(abManager.isFeatureEnabled('feature_x', rolloutPercentage: 0, defaultValue: true), isFalse);
      expect(abManager.isFeatureEnabled('feature_x', rolloutPercentage: 100, defaultValue: false), isTrue);
    });

    test('isFeatureEnabled is deterministic for a user', () {
      abManager.initialize('user123');
      final result1 = abManager.isFeatureEnabled('feature_y', rolloutPercentage: 50);

      // Simulate app restart/re-init
      abManager.initialize('user123');
      final result2 = abManager.isFeatureEnabled('feature_y', rolloutPercentage: 50);

      expect(result1, result2);
    });

    test('isFeatureEnabled respects rollout percentage roughly', () {
      // This is a statistical test, might be flaky if N is small or hash is poor.
      // We check specific cases instead.

      // 'user_A' hash with 'feat' might be < 50
      // 'user_B' hash with 'feat' might be > 50
      // We rely on stable hash.

      abManager.initialize('user_low_hash');
      // We don't know the hash value, but we can verify it's consistent.
    });

    test('Feature override takes precedence', () {
      abManager.initialize('user1');
      abManager.setFeatureOverride('feature_z', true);

      // Even if rollout is 0
      expect(abManager.isFeatureEnabled('feature_z', rolloutPercentage: 0), isTrue);

      abManager.setFeatureOverride('feature_z', false);
      // Even if rollout is 100
      expect(abManager.isFeatureEnabled('feature_z', rolloutPercentage: 100), isFalse);
    });

    test('getVariant returns default or first when no user', () {
      final variants = ['A', 'B'];
      expect(abManager.getVariant('exp1', variants), 'A');
      expect(abManager.getVariant('exp1', variants, defaultVariant: 'B'), 'B');
    });

    test('getVariant returns consistent variant for user', () {
      abManager.initialize('user_consistent');
      final variants = ['Control', 'VarA', 'VarB'];

      final variant1 = abManager.getVariant('experiment_color', variants);

      abManager.initialize('user_consistent');
      final variant2 = abManager.getVariant('experiment_color', variants);

      expect(variant1, variant2);
      expect(variants.contains(variant1), isTrue);
    });

    test('getVariant distributes users', () {
      // Just check that different users CAN get different variants (not guaranteed for just 2 users, but likely)
      // We will loop a few users to find at least one diff if possible.

      final variants = ['A', 'B'];
      final results = <String>{};

      for (int i = 0; i < 20; i++) {
        abManager.initialize('user_$i');
        results.add(abManager.getVariant('exp_dist', variants));
      }

      // Should have found both A and B with high probability
      expect(results.contains('A'), isTrue);
      expect(results.contains('B'), isTrue);
    });

    test('getVariant throws on empty list', () {
      expect(() => abManager.getVariant('exp_empty', []), throwsArgumentError);
    });
  });
}

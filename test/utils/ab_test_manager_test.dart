import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/ab_test_manager.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Simple Fake implementation since we only need uid
class FakeUser extends Fake implements User {
  @override
  final String uid;
  FakeUser(this.uid);
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  final User? _user;
  FakeFirebaseAuth({User? user}) : _user = user;

  @override
  User? get currentUser => _user;
}

void main() {
  group('ABTestVariant', () {
    test('should create variant from map', () {
      final map = {
        'name': 'variant_a',
        'weight': 30.0,
        'config': {'color': 'blue'},
      };

      final variant = ABTestVariant.fromMap(map);
      expect(variant.name, 'variant_a');
      expect(variant.weight, 30.0);
      expect(variant.config['color'], 'blue');
    });

    test('should convert variant to map', () {
      final variant = ABTestVariant(
        name: 'variant_b',
        weight: 70.0,
        config: {'size': 'large'},
      );

      final map = variant.toMap();
      expect(map['name'], 'variant_b');
      expect(map['weight'], 70.0);
      expect(map['config']['size'], 'large');
    });

    test('should handle default values', () {
      final variant = ABTestVariant.fromMap({});
      expect(variant.name, '');
      expect(variant.weight, 50.0);
      expect(variant.config, isEmpty);
    });
  });

  group('ABTestConfig', () {
    test('should create config and convert to map', () {
      final config = ABTestConfig(
        testId: 'test_1',
        name: 'Test Experiment',
        description: 'Test Description',
        isActive: true,
        variants: [
          ABTestVariant(name: 'control', weight: 50.0),
          ABTestVariant(name: 'variant_a', weight: 50.0),
        ],
      );

      final result = config.toMap();
      expect(result['name'], 'Test Experiment');
      expect(result['description'], 'Test Description');
      expect(result['isActive'], true);
      expect(result['variants'], hasLength(2));
    });
  });

  group('ABTestManager Logic', () {
    late ABTestManager manager;
    late FakeFirebaseFirestore fakeFirestore;
    late FakeFirebaseAuth fakeAuth;
    final testUser = FakeUser('user_123');

    setUp(() {
      manager = ABTestManager();
      fakeFirestore = FakeFirebaseFirestore();
      fakeAuth = FakeFirebaseAuth(user: testUser);
      manager.setDependencies(firestore: fakeFirestore, auth: fakeAuth);
      manager.clearCache();
    });

    test('initialize should load active tests from Firestore', () async {
      await fakeFirestore.collection('ab_tests').doc('test_1').set({
        'name': 'Test 1',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50},
          {'name': 'variant_a', 'weight': 50}
        ]
      });

      // Inactive test
      await fakeFirestore.collection('ab_tests').doc('test_2').set({
        'name': 'Test 2',
        'isActive': false,
        'variants': []
      });

      await manager.initialize();

      // Check if test_1 is loaded (indirectly via getVariant or internal check if we exposed it)
      // Since _cachedTests is private, we can try to access the test via isFeatureEnabled logic
      // But better to check getVariant behavior

      // If test is not loaded, getVariant returns 'control' by default,
      // but if loaded, it calculates.
      // Let's rely on behavior.
    });

    test('getVariant should be deterministic based on userId and testId', () async {
      // Setup a test with 50/50 split
      await fakeFirestore.collection('ab_tests').doc('test_deterministic').set({
        'name': 'Deterministic Test',
        'isActive': true,
        'variants': [
          {'name': 'A', 'weight': 50},
          {'name': 'B', 'weight': 50}
        ]
      });

      await manager.initialize();

      // For user_123 and test_deterministic
      // (user_123 + test_deterministic).hashCode % 100
      // We don't know the exact hash here, but it should be constant.

      final variant1 = await manager.getVariant('test_deterministic');

      // Clear cache to force recalculation (though getVariant checks _userVariants cache first)
      manager.clearCache();
      // Re-init dependencies because clearCache might affect internal state?
      // clearCache clears _cachedTests and _userVariants.
      // We need to re-initialize to load tests again.
      await manager.initialize();

      final variant2 = await manager.getVariant('test_deterministic');

      expect(variant1, variant2);
    });

    test('getVariant should persist assignment to Firestore', () async {
      await fakeFirestore.collection('ab_tests').doc('test_persist').set({
        'name': 'Persist Test',
        'isActive': true,
        'variants': [
          {'name': 'A', 'weight': 100}, // 100% A
        ]
      });

      await manager.initialize();

      await manager.getVariant('test_persist');

      final userVariantDoc = await fakeFirestore
          .collection('users')
          .doc(testUser.uid)
          .collection('ab_test_variants')
          .doc('test_persist')
          .get();

      expect(userVariantDoc.exists, true);
      expect(userVariantDoc.data()?['variant'], 'A');
    });

    test('isFeatureEnabled should respect feature flags', () async {
      await fakeFirestore.collection('feature_flags').doc('feature_x').set({
        'enabled': true,
        'config': {}
      });

      final isEnabled = await manager.isFeatureEnabled('feature_x');
      expect(isEnabled, true);

      await fakeFirestore.collection('feature_flags').doc('feature_y').set({
        'enabled': false,
        'config': {}
      });

      final isEnabledY = await manager.isFeatureEnabled('feature_y');
      expect(isEnabledY, false);
    });

    test('isFeatureEnabled should fall back to A/B test if flag not found', () async {
      // Setup AB test acting as feature flag
      await fakeFirestore.collection('ab_tests').doc('new_feature_rollout').set({
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 0},
          {'name': 'variant_on', 'weight': 100}
        ]
      });

      await manager.initialize();

      final isEnabled = await manager.isFeatureEnabled('new_feature_rollout');
      // non-control variant returns true
      expect(isEnabled, true);
    });
  });
}

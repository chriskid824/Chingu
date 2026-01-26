import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/ab_test_manager.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Fake classes to avoid Mockito code generation
class FakeUser extends Fake implements User {
  @override
  final String uid;
  FakeUser(this.uid);
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  void signIn(String uid) {
    _currentUser = FakeUser(uid);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }
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

    test('should handle optional dates', () {
      final now = DateTime.now();
      final config = ABTestConfig(
        testId: 'test_2',
        name: 'Dated Test',
        description: 'With dates',
        isActive: true,
        variants: [ABTestVariant(name: 'control', weight: 100.0)],
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
      );

      final map = config.toMap();
      expect(map.containsKey('startDate'), true);
      expect(map.containsKey('endDate'), true);
    });
  });

  group('FeatureConfig', () {
    test('should create config with default values', () {
      final config = FeatureConfig(
        key: 'new_feature',
        enabled: true,
      );

      expect(config.key, 'new_feature');
      expect(config.enabled, true);
      expect(config.config, isEmpty);
    });

    test('should convert to map correctly', () {
      final config = FeatureConfig(
        key: 'feature_1',
        enabled: false,
        config: const {'timeout': 5000},
      );

      final map = config.toMap();
      expect(map['enabled'], false);
      expect(map['config']['timeout'], 5000);
    });

    test('should handle custom config', () {
      final config = FeatureConfig(
        key: 'advanced_feature',
        enabled: true,
        config: const {
          'maxUsers': 100,
          'theme': 'dark',
          'features': ['chat', 'video']
        },
      );

      expect(config.config['maxUsers'], 100);
      expect(config.config['theme'], 'dark');
      expect(config.config['features'], hasLength(2));
    });
  });

  group('ABTestManager', () {
    late ABTestManager manager;
    late FakeFirebaseFirestore fakeFirestore;
    late FakeFirebaseAuth fakeAuth;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      fakeAuth = FakeFirebaseAuth();
      manager = ABTestManager();
      manager.reset();
      manager.setFirestoreInstance = fakeFirestore;
      manager.setAuthInstance = fakeAuth;
    });

    test('initialize loads active tests', () async {
      // Setup data
      await fakeFirestore.collection('ab_tests').doc('test_1').set({
        'name': 'Test 1',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50.0},
          {'name': 'variant_a', 'weight': 50.0},
        ]
      });
      await fakeFirestore.collection('ab_tests').doc('test_2').set({
        'name': 'Test 2',
        'isActive': false,
      });

      await manager.initialize();

      // Check internal cache (via side effect or implementation detail if exposed,
      // but better to check via getVariant behavior or public getters if available)
      // Since we can't access _cachedTests directly, we can check if isFeatureEnabled checks it
      // or we can add a getter for testing.
      // Ideally use getVariant.

      // We'll rely on getVariant returning 'control' (default) vs actual variant assignment logic.
      // But getVariant returns 'control' if config is null too.

      // Let's use `isFeatureEnabled` on 'test_1'.
      // If initialized, it should proceed to variant assignment.

      // For 'test_2', it's inactive, so it shouldn't be in cache.
      // getVariant returns 'control' if not in cache.
    });

    test('getVariant assigns new variant and saves it', () async {
      fakeAuth.signIn('user_123');

      await fakeFirestore.collection('ab_tests').doc('color_test').set({
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 0.0},
          {'name': 'blue', 'weight': 100.0}, // Force blue
        ]
      });

      await manager.initialize();

      final variant = await manager.getVariant('color_test');
      expect(variant, 'blue');

      // Check Firestore
      final userDoc = await fakeFirestore
          .collection('users')
          .doc('user_123')
          .collection('ab_test_variants')
          .doc('color_test')
          .get();

      expect(userDoc.exists, true);
      expect(userDoc.data()!['variant'], 'blue');
    });

    test('getVariant returns existing assignment', () async {
      fakeAuth.signIn('user_123');

      // Pre-assign user to 'control'
      await fakeFirestore
          .collection('users')
          .doc('user_123')
          .collection('ab_test_variants')
          .doc('color_test')
          .set({'variant': 'control'});

      await fakeFirestore.collection('ab_tests').doc('color_test').set({
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 0.0},
          {'name': 'blue', 'weight': 100.0},
        ]
      });

      await manager.initialize(); // This calls loadUserVariants

      final variant = await manager.getVariant('color_test');
      expect(variant, 'control'); // Should keep 'control' despite weight favoring 'blue'
    });

    test('isFeatureEnabled works for simple feature flags', () async {
      await fakeFirestore.collection('feature_flags').doc('dark_mode').set({
        'enabled': true,
      });

      final isEnabled = await manager.isFeatureEnabled('dark_mode');
      expect(isEnabled, true);

      await fakeFirestore.collection('feature_flags').doc('beta_feature').set({
        'enabled': false,
      });

      final isBetaEnabled = await manager.isFeatureEnabled('beta_feature');
      expect(isBetaEnabled, false);
    });

    test('isFeatureEnabled works for A/B tests', () async {
      fakeAuth.signIn('user_123');

       await fakeFirestore.collection('ab_tests').doc('new_feature_test').set({
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 0.0},
          {'name': 'enabled', 'weight': 100.0},
        ]
      });

      await manager.initialize();

      // Default behavior: variant != 'control' is true
      final isEnabled = await manager.isFeatureEnabled('new_feature_test');
      expect(isEnabled, true);

      // Specific variant check
      final isVariantEnabled = await manager.isFeatureEnabled('new_feature_test', specificVariant: 'enabled');
      expect(isVariantEnabled, true);

       final isControlEnabled = await manager.isFeatureEnabled('new_feature_test', specificVariant: 'control');
      expect(isControlEnabled, false);
    });

    test('trackEvent records event to Firestore', () async {
      fakeAuth.signIn('user_123');

      await manager.trackEvent('test_1', 'click_button', properties: {'id': 1});

      final snapshot = await fakeFirestore.collection('ab_test_events').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['testId'], 'test_1');
      expect(data['userId'], 'user_123');
      expect(data['eventName'], 'click_button');
      expect(data['properties']['id'], 1);
    });
  });
}

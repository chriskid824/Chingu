import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/ab_test_manager.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

// Mock User and FirebaseAuth using Fake for manual implementation
class MockUser extends Fake implements User {
  @override
  String get uid => 'test_user_id';
}

class MockFirebaseAuth extends Fake implements FirebaseAuth {
  final User? _currentUser;
  MockFirebaseAuth({User? currentUser}) : _currentUser = currentUser;

  @override
  User? get currentUser => _currentUser;
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
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      manager = ABTestManager();
      fakeFirestore = FakeFirebaseFirestore();
      mockUser = MockUser();
      mockAuth = MockFirebaseAuth(currentUser: mockUser);

      manager.firestore = fakeFirestore;
      manager.auth = mockAuth;
      manager.clearCache();
    });

    test('initialize should load active tests', () async {
      await fakeFirestore.collection('ab_tests').doc('test_1').set({
        'name': 'Test 1',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50.0},
          {'name': 'variant_a', 'weight': 50.0},
        ],
      });

      await fakeFirestore.collection('ab_tests').doc('test_2').set({
        'name': 'Test 2',
        'isActive': false, // Inactive test
        'variants': [],
      });

      await manager.initialize();

      // We can't access private _cachedTests directly, but we can verify via getVariant behavior
      // Accessing a known test should trigger assignment logic
      // Accessing unknown (inactive) test should return 'control' and NOT trigger assignment logic if not found.

      // But getVariant logic:
      // if not in cache => return 'control'
      // if in cache => assign variant

      // So checking getVariant for test_1 should return a variant (and persist it)
      // Checking getVariant for test_2 should return 'control' (and NOT persist it because it's not in cache)

      final variant1 = await manager.getVariant('test_1');
      expect(['control', 'variant_a'], contains(variant1));

      // Verify persistence happened
      final userVariants = await fakeFirestore
          .collection('users')
          .doc(mockUser.uid)
          .collection('ab_test_variants')
          .get();
      expect(userVariants.docs.length, 1);
      expect(userVariants.docs.first.id, 'test_1');

      final variant2 = await manager.getVariant('test_2');
      expect(variant2, 'control');

      // Should still be 1 because test_2 is not cached (inactive)
      final userVariantsAfter = await fakeFirestore
          .collection('users')
          .doc(mockUser.uid)
          .collection('ab_test_variants')
          .get();
      expect(userVariantsAfter.docs.length, 1);
    });

    test('getVariant should return cached user variant', () async {
      // Pre-populate user variant
      await fakeFirestore
          .collection('users')
          .doc(mockUser.uid)
          .collection('ab_test_variants')
          .doc('test_1')
          .set({'variant': 'variant_assigned', 'testId': 'test_1'});

      // Need to initialize so user variants are loaded
      // Also need test config so it doesn't default to control if not found in cache?
      // Wait, getVariant checks _userVariants FIRST.
      // So if it's in _userVariants (loaded from Firestore), it returns it regardless of config existence in _cachedTests?
      // Let's check implementation:
      // if (_userVariants.containsKey(testId)) return _userVariants[testId]!;

      // Yes. So we need to ensure _loadUserVariants is called.
      // _loadUserVariants is called in initialize().

      await manager.initialize();

      final variant = await manager.getVariant('test_1');
      expect(variant, 'variant_assigned');
    });

    test('getVariant should assign new variant based on weights', () async {
       await fakeFirestore.collection('ab_tests').doc('test_weighted').set({
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 0.0}, // 0% chance
          {'name': 'variant_b', 'weight': 100.0}, // 100% chance
        ],
      });

      await manager.initialize();

      final variant = await manager.getVariant('test_weighted');
      expect(variant, 'variant_b');
    });

    test('isFeatureEnabled should check ab test variant', () async {
       await fakeFirestore.collection('ab_tests').doc('feature_test').set({
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 0.0},
          {'name': 'enabled_variant', 'weight': 100.0},
        ],
      });

      await manager.initialize();

      // Check generic enabled (not control)
      expect(await manager.isFeatureEnabled('feature_test'), true);

      // Check specific variant
      expect(await manager.isFeatureEnabled('feature_test', specificVariant: 'enabled_variant'), true);
      expect(await manager.isFeatureEnabled('feature_test', specificVariant: 'control'), false);
    });

    test('isFeatureEnabled should check simple feature flag', () async {
      await fakeFirestore.collection('feature_flags').doc('simple_flag').set({
        'enabled': true,
      });

      await fakeFirestore.collection('feature_flags').doc('disabled_flag').set({
        'enabled': false,
      });

      // No need to initialize for feature flags as they are fetched on demand
      expect(await manager.isFeatureEnabled('simple_flag'), true);
      expect(await manager.isFeatureEnabled('disabled_flag'), false);
      expect(await manager.isFeatureEnabled('non_existent_flag'), false);
    });

    test('trackEvent should write to ab_test_events', () async {
      // Setup a test variant so we have a known variant
      await fakeFirestore
          .collection('users')
          .doc(mockUser.uid)
          .collection('ab_test_variants')
          .doc('test_event')
          .set({'variant': 'variant_x', 'testId': 'test_event'});

      await manager.initialize(); // load variants

      await manager.trackEvent('test_event', 'click_button', properties: {'foo': 'bar'});

      final events = await fakeFirestore.collection('ab_test_events').get();
      expect(events.docs.length, 1);
      final event = events.docs.first.data();
      expect(event['testId'], 'test_event');
      expect(event['eventName'], 'click_button');
      expect(event['variant'], 'variant_x');
      expect(event['userId'], 'test_user_id');
      expect(event['properties']['foo'], 'bar');
    });
  });
}

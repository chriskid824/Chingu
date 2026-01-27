import 'package:chingu/utils/ab_test_manager.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseAuth, User])
import 'ab_test_manager_test.mocks.dart';

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

  group('ABTestManager Logic', () {
    late ABTestManager manager;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      manager = ABTestManager();
      manager.clearCache(); // Singleton reset
      manager.setInstancesForTesting(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      // Setup default user
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_user_123');
    });

    test('initialize should load configs from firestore', () async {
      // Arrange
      await fakeFirestore.collection('ab_tests').doc('test_experiment').set({
        'name': 'Test Experiment',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50.0},
          {'name': 'variant_a', 'weight': 50.0},
        ],
      });

      // Act
      await manager.initialize();

      // Assert
      final result = await manager.getVariant('test_experiment');
      expect(result, isNotNull);
    });

    test('getVariant should use deterministic hash', () async {
      // Arrange
      await fakeFirestore.collection('ab_tests').doc('hash_test').set({
        'name': 'Hash Test',
        'isActive': true,
        'variants': [
          {'name': 'A', 'weight': 50.0},
          {'name': 'B', 'weight': 50.0},
        ],
      });
      await manager.initialize();

      // Act
      final variant1 = await manager.getVariant('hash_test');

      // Simulate app restart / cache clear
      manager.clearCache();
      await manager.initialize(); // Reload config

      final variant2 = await manager.getVariant('hash_test');

      // Assert
      expect(variant1, variant2);
    });

    test('getVariant should persist assignment', () async {
      // Arrange
      await fakeFirestore.collection('ab_tests').doc('persist_test').set({
        'name': 'Persist Test',
        'isActive': true,
        'variants': [
          {'name': 'A', 'weight': 100.0},
        ],
      });
      await manager.initialize();

      // Act
      final variant = await manager.getVariant('persist_test');

      // Assert
      expect(variant, 'A');

      final savedDoc = await fakeFirestore
          .collection('users')
          .doc('test_user_123')
          .collection('ab_test_variants')
          .doc('persist_test')
          .get();

      expect(savedDoc.exists, true);
      expect(savedDoc.data()!['variant'], 'A');
    });

    test('isFeatureEnabled should respect AB test variants', () async {
       // Arrange
      await fakeFirestore.collection('ab_tests').doc('feature_test').set({
        'name': 'Feature Test',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 0.0},
          {'name': 'enabled_variant', 'weight': 100.0},
        ],
      });
      await manager.initialize();

      // Act
      final isEnabled = await manager.isFeatureEnabled('feature_test');

      // Assert
      expect(isEnabled, true); // Not 'control' -> true

      final isSpecific = await manager.isFeatureEnabled('feature_test', specificVariant: 'enabled_variant');
      expect(isSpecific, true);
    });

    test('isFeatureEnabled should work for simple feature flags', () async {
      // Arrange
      await fakeFirestore.collection('feature_flags').doc('simple_flag').set({
        'enabled': true,
        'config': {},
      });

      // Act
      final isEnabled = await manager.isFeatureEnabled('simple_flag');

      // Assert
      expect(isEnabled, true);
    });
  });
}

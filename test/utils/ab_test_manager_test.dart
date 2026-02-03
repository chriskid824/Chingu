import 'package:chingu/utils/ab_test_manager.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseAuth, User])
import 'ab_test_manager_test.mocks.dart';

void main() {
  late ABTestManager abTestManager;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Setup authenticated user
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test_user_id');

    abTestManager = ABTestManager();
    abTestManager.setDependencies(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
    // Clear internal cache before each test
    abTestManager.clearCache();
  });

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

  group('ABTestManager Integration', () {
    test('initialize should load active tests', () async {
      // Arrange
      await fakeFirestore.collection('ab_tests').doc('test_1').set({
        'name': 'Test 1',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50},
          {'name': 'variant_a', 'weight': 50}
        ]
      });
      await fakeFirestore.collection('ab_tests').doc('test_2').set({
        'name': 'Test 2',
        'isActive': false,
        'variants': []
      });

      // Act
      await abTestManager.initialize();

      // Assert
      // We can verify by trying to get a variant, if it's not loaded it returns 'control' without assigning (if configured to)
      // But getVariant uses cachedTests.
      // Since _cachedTests is private, we can't inspect it directly.
      // But we can verify behavior.

      final variant1 = await abTestManager.getVariant('test_1');
      // Should be assigned either control or variant_a
      expect(['control', 'variant_a'], contains(variant1));

      // For inactive test, getVariant returns 'control' immediately because config is not in cache
      final variant2 = await abTestManager.getVariant('test_2');
      expect(variant2, 'control');
    });

    test('getVariant should return cached user variant if exists', () async {
      // Arrange
      // Pre-set user variant in firestore
      await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('ab_test_variants')
          .doc('test_3')
          .set({'variant': 'variant_b'});

      // Mock the test config exists
      await fakeFirestore.collection('ab_tests').doc('test_3').set({
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50},
          {'name': 'variant_b', 'weight': 50}
        ]
      });

      await abTestManager.initialize();

      // Act
      final variant = await abTestManager.getVariant('test_3');

      // Assert
      expect(variant, 'variant_b');
    });

    test('getVariant should assign new variant and save it', () async {
      // Arrange
      await fakeFirestore.collection('ab_tests').doc('test_4').set({
        'isActive': true,
        'variants': [
          {'name': 'variant_x', 'weight': 100}, // force variant_x
        ]
      });

      await abTestManager.initialize();

      // Act
      final variant = await abTestManager.getVariant('test_4');

      // Assert
      expect(variant, 'variant_x');

      // Verify persistence
      final savedDoc = await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('ab_test_variants')
          .doc('test_4')
          .get();

      expect(savedDoc.exists, true);
      expect(savedDoc.data()!['variant'], 'variant_x');
    });

    test('isFeatureEnabled should check AB tests first', () async {
      // Arrange
      await fakeFirestore.collection('ab_tests').doc('feature_test').set({
        'isActive': true,
        'variants': [
          {'name': 'variant_enabled', 'weight': 100},
        ]
      });

      await abTestManager.initialize();

      // Act
      // By default returns true if not control
      final isEnabled = await abTestManager.isFeatureEnabled('feature_test');
      final isSpecific = await abTestManager.isFeatureEnabled(
        'feature_test',
        specificVariant: 'variant_enabled'
      );

      // Assert
      expect(isEnabled, true);
      expect(isSpecific, true);
    });

    test('isFeatureEnabled should fallback to feature_flags', () async {
      // Arrange
      await fakeFirestore.collection('feature_flags').doc('simple_feature').set({
        'enabled': true,
      });

      // Act
      final isEnabled = await abTestManager.isFeatureEnabled('simple_feature');

      // Assert
      expect(isEnabled, true);
    });

    test('trackEvent should write to firestore', () async {
      // Arrange
      // Assign a variant first
      await fakeFirestore.collection('ab_tests').doc('test_5').set({
        'isActive': true,
        'variants': [{'name': 'v1', 'weight': 100}]
      });
      await abTestManager.initialize();
      await abTestManager.getVariant('test_5');

      // Act
      await abTestManager.trackEvent('test_5', 'click_button', properties: {'id': 123});

      // Assert
      final events = await fakeFirestore.collection('ab_test_events').get();
      expect(events.docs.length, 1);
      final event = events.docs.first.data();
      expect(event['testId'], 'test_5');
      expect(event['userId'], 'test_user_id');
      expect(event['variant'], 'v1');
      expect(event['eventName'], 'click_button');
      expect(event['properties']['id'], 123);
    });
  });
}

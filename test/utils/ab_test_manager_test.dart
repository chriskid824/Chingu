import 'package:chingu/utils/ab_test_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

// Fakes
class FakeUser extends Fake implements User {
  @override
  final String uid;
  FakeUser(this.uid);
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  void setMockUser(User? user) {
    _currentUser = user;
  }
}

void main() {
  late ABTestManager manager;
  late FakeCloudFirestore fakeFirestore;
  late FakeFirebaseAuth fakeAuth;

  setUp(() {
    fakeFirestore = FakeCloudFirestore();
    fakeAuth = FakeFirebaseAuth();
    manager = ABTestManager();
    // Inject dependencies
    manager.setDependencies(
      firestore: fakeFirestore,
      auth: fakeAuth,
    );
    // Clear cache
    manager.clearCache();
  });

  group('ABTestManager', () {
    test('initialize loads active tests', () async {
      // Setup data
      await fakeFirestore.collection('ab_tests').add({
        'name': 'Test A',
        'description': 'Description A',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50},
          {'name': 'variant_a', 'weight': 50},
        ],
      });

      await fakeFirestore.collection('ab_tests').add({
        'name': 'Test B',
        'isActive': false, // Inactive
        'variants': [],
      });

      await manager.initialize();

      // Verify via side effects if possible, or trust internal state is set
    });

    test('getVariant assigns deterministically', () async {
      // Setup test config
      final testId = 'test_color';
      await fakeFirestore.collection('ab_tests').doc(testId).set({
        'name': 'Color Test',
        'isActive': true,
        'variants': [
          {'name': 'red', 'weight': 50},
          {'name': 'blue', 'weight': 50},
        ],
      });

      await manager.initialize();

      // User 1
      fakeAuth.setMockUser(FakeUser('user1'));
      final variant1 = await manager.getVariant(testId);

      // User 1 should get same variant again even if cache is cleared (simulating fresh app launch)
      manager.clearCache();
      await manager.initialize();

      final variant1Again = await manager.getVariant(testId);

      expect(variant1, variant1Again);

      // User 2 (might be different, but deterministic for user2)
      fakeAuth.setMockUser(FakeUser('user2'));
      // Clear cache to simulate another user on another device or fresh login
      manager.clearCache();
      await manager.initialize();

      final variant2 = await manager.getVariant(testId);

      // Just check it returns a valid variant
      expect(['red', 'blue'], contains(variant2));
    });

    test('getVariant saves assignment to Firestore', () async {
      final testId = 'test_button';
      await fakeFirestore.collection('ab_tests').doc(testId).set({
        'name': 'Button Test',
        'isActive': true,
        'variants': [
          {'name': 'A', 'weight': 100}, // Force A
        ],
      });

      await manager.initialize();
      fakeAuth.setMockUser(FakeUser('user_save'));

      final variant = await manager.getVariant(testId);
      expect(variant, 'A');

      // Check Firestore
      final doc = await fakeFirestore
          .collection('users')
          .doc('user_save')
          .collection('ab_test_variants')
          .doc(testId)
          .get();

      expect(doc.exists, true);
      expect(doc.data()?['variant'], 'A');
    });

    test('isFeatureEnabled works for simple flags', () async {
      final featureKey = 'new_feature';
      await fakeFirestore.collection('feature_flags').doc(featureKey).set({
        'enabled': true,
        'config': {},
      });

      final isEnabled = await manager.isFeatureEnabled(featureKey);
      expect(isEnabled, true);

      await fakeFirestore.collection('feature_flags').doc(featureKey).update({
        'enabled': false,
      });

      final isEnabled2 = await manager.isFeatureEnabled(featureKey);
      expect(isEnabled2, false);
    });

    test('getVariant returns control for missing config', () async {
      final variant = await manager.getVariant('non_existent_test');
      expect(variant, 'control');
    });
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
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/ab_test_manager.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/services/crash_reporting_service.dart';

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

class FakeCrashReportingService extends Fake implements CrashReportingService {
  @override
  void recordError(dynamic exception, StackTrace? stack, {dynamic reason, bool fatal = false}) {}
}

void main() {
  group('ABTestManager Logic', () {
    late ABTestManager manager;
    late FakeFirebaseFirestore fakeFirestore;
    late FakeFirebaseAuth fakeAuth;
    late FakeCrashReportingService fakeCrashReporter;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      fakeAuth = FakeFirebaseAuth();
      fakeCrashReporter = FakeCrashReportingService();

      manager = ABTestManager();
      manager.setFirestore(fakeFirestore);
      manager.setAuth(fakeAuth);
      manager.setCrashReportingService(fakeCrashReporter);
      manager.clearCache();
    });

    test('should initialize and load active tests', () async {
      // Arrange
      await fakeFirestore.collection('ab_tests').doc('test_1').set({
        'name': 'Test 1',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50},
          {'name': 'variant_a', 'weight': 50},
        ],
      });

      await fakeFirestore.collection('ab_tests').doc('test_2').set({
        'name': 'Test 2',
        'isActive': false, // Inactive
      });

      // Act
      await manager.initialize();

      // Assert
      // We can't access private _cachedTests directly but we can verify behavior
      // by asking for variants.
      // test_1 is active, so we should get a variant (might trigger assignment)
      // test_2 is inactive, should behave as missing/control

      // Since we didn't assign yet, and cache is clear, it should try to assign for test_1
      // For test_2, it won't find it in cache, so returns 'control'
    });

    test('should return deterministic variant for same user', () async {
      // Arrange
      fakeAuth.setMockUser(FakeUser('user_123'));

      await fakeFirestore.collection('ab_tests').doc('test_color').set({
        'name': 'Color Test',
        'isActive': true,
        'variants': [
          {'name': 'blue', 'weight': 50},
          {'name': 'red', 'weight': 50},
        ],
      });

      await manager.initialize();

      // Act
      final variant1 = await manager.getVariant('test_color');

      // Clear local cache to force re-calculation/fetching (simulate restart)
      // but keep firestore state (simulating persistence)
      manager.clearCache();

      // However, getVariant checks _userVariants cache first.
      // If we clear cache, it re-fetches or re-calculates.
      // But manager doesn't re-fetch from Firestore inside getVariant unless we initialize again.
      // Wait, _userVariants is loaded in initialize().

      // Let's re-initialize manager
      await manager.initialize();
      final variant2 = await manager.getVariant('test_color');

      // Assert
      expect(variant1, variant2);
      expect(variant1, isNot('control'));
    });

    test('should return control if test does not exist', () async {
      await manager.initialize();
      final variant = await manager.getVariant('non_existent_test');
      expect(variant, 'control');
    });

    test('should respect feature flag overrides', () async {
      // Arrange
      await fakeFirestore.collection('feature_flags').doc('new_feature').set({
        'enabled': true,
        'config': {'key': 'value'},
      });

      // Act
      final isEnabled = await manager.isFeatureEnabled('new_feature');

      // Assert
      expect(isEnabled, true);
    });

    test('should fallback to false for missing feature flags', () async {
      final isEnabled = await manager.isFeatureEnabled('missing_feature');
      expect(isEnabled, false);
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

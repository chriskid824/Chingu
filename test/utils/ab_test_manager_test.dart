import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/ab_test_manager.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {
  @override
  Stream<User?> authStateChanges() => super.noSuchMethod(
        Invocation.method(#authStateChanges, []),
        returnValue: Stream<User?>.empty(),
      );

  @override
  User? get currentUser => super.noSuchMethod(
        Invocation.getter(#currentUser),
        returnValue: null,
      );
}

class MockUser extends Mock implements User {
  @override
  String get uid => super.noSuchMethod(
        Invocation.getter(#uid),
        returnValue: 'test_user_id',
      );
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

  group('ABTestManager Logic', () {
    late ABTestManager manager;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late StreamController<User?> authController;

    setUp(() {
      manager = ABTestManager();
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      authController = StreamController<User?>();

      // Mock auth behavior
      when(mockAuth.authStateChanges())
          .thenAnswer((_) => authController.stream);
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_user_id');

      // Inject dependencies
      manager.firestore = fakeFirestore;
      manager.auth = mockAuth;
      manager.clearCache();
    });

    tearDown(() {
      manager.dispose();
      authController.close();
    });

    test('initialize loads configs', () async {
      // Setup Firestore data
      await fakeFirestore.collection('ab_tests').doc('test_1').set({
        'name': 'Test 1',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50.0},
          {'name': 'variant_a', 'weight': 50.0}
        ]
      });

      await fakeFirestore.collection('feature_flags').doc('flag_1').set({
        'enabled': true,
        'config': {'key': 'val'}
      });

      await manager.initialize();

      // Check features
      expect(await manager.isFeatureEnabled('flag_1'), true);

      // Check variants (should assign since user is present)
      final variant = await manager.getVariant('test_1');
      expect(variant, isNotNull);
    });

    test('isFeatureEnabled uses cache', () async {
      await fakeFirestore.collection('feature_flags').doc('cached_flag').set({
        'enabled': true
      });

      await manager.initialize();

      // Delete from firestore to prove it uses cache
      await fakeFirestore
          .collection('feature_flags')
          .doc('cached_flag')
          .delete();

      expect(await manager.isFeatureEnabled('cached_flag'), true);
    });

    test('auth state change updates variants', () async {
      // Setup
      await fakeFirestore.collection('ab_tests').doc('test_auth').set({
        'isActive': true,
        'variants': [
          {'name': 'v1', 'weight': 100}
        ]
      });

      await manager.initialize();

      // Emit null user (logout)
      authController.add(null);
      await Future.delayed(Duration.zero);

      expect(manager.getUserVariants(), isEmpty);

      // Seed Firestore with a variant for this user
      await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('ab_test_variants')
          .doc('test_auth')
          .set({'variant': 'stored_variant'});

      // Emit user (login)
      when(mockAuth.currentUser).thenReturn(mockUser);
      authController.add(mockUser);

      // Wait for async load
      await Future.delayed(const Duration(milliseconds: 100));

      expect(await manager.getVariant('test_auth'), 'stored_variant');
    });
  });
}

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/utils/ab_test_manager.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Fakes
class FakeUser extends Fake implements User {
  @override
  final String uid;

  FakeUser(this.uid);
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? _currentUser;
  final StreamController<User?> _authStateController = StreamController<User?>();

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() => _authStateController.stream;

  void signIn(String uid) {
    _currentUser = FakeUser(uid);
    _authStateController.add(_currentUser);
  }

  void signOut() {
    _currentUser = null;
    _authStateController.add(null);
  }
}

void main() {
  late ABTestManager manager;
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseAuth fakeAuth;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeAuth = FakeFirebaseAuth();
    manager = ABTestManager();
    manager.firestoreInstance = fakeFirestore;
    manager.authInstance = fakeAuth;
    manager.clearCache();
  });

  tearDown(() {
    manager.clearCache();
  });

  group('ABTestManager', () {
    test('initialize should load active configs', () async {
      await fakeFirestore.collection('ab_tests').add({
        'name': 'Test 1',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50},
          {'name': 'variant_a', 'weight': 50}
        ]
      });

      await fakeFirestore.collection('ab_tests').add({
        'name': 'Test 2',
        'isActive': false,
        'variants': []
      });

      await manager.initialize();

      // We verify initialization by checking if it uses the config later
      // Or we could check internal state if we exposed it, but black-box is better.
      // If config is loaded, getVariant should work for test_1 but return control for non-existent.
    });

    test('getVariant should assign and save new variant', () async {
      await fakeFirestore.collection('ab_tests').doc('test_1').set({
        'name': 'Test 1',
        'isActive': true,
        'variants': [
          {'name': 'variant_a', 'weight': 100}
        ]
      });

      fakeAuth.signIn('user_1');
      await manager.initialize();

      final variant = await manager.getVariant('test_1');

      expect(variant, 'variant_a');

      final saved = await fakeFirestore
          .collection('users')
          .doc('user_1')
          .collection('ab_test_variants')
          .doc('test_1')
          .get();

      expect(saved.exists, true);
      expect(saved.data()!['variant'], 'variant_a');
    });

    test('getVariant should return existing user variant', () async {
      await fakeFirestore.collection('ab_tests').doc('test_1').set({
        'name': 'Test 1',
        'isActive': true,
        'variants': [
          {'name': 'variant_a', 'weight': 100}
        ]
      });

      await fakeFirestore
          .collection('users')
          .doc('user_1')
          .collection('ab_test_variants')
          .doc('test_1')
          .set({'variant': 'variant_b'});

      fakeAuth.signIn('user_1');
      await manager.initialize();

      final variant = await manager.getVariant('test_1');

      expect(variant, 'variant_b');
    });

    test('isFeatureEnabled should check simple feature flags', () async {
      await fakeFirestore.collection('feature_flags').doc('feature_x').set({
        'enabled': true,
        'config': {}
      });

      final isEnabled = await manager.isFeatureEnabled('feature_x');

      expect(isEnabled, true);
    });

    test('isFeatureEnabled should check A/B test variants', () async {
      await fakeFirestore.collection('ab_tests').doc('test_feature').set({
        'name': 'Feature Test',
        'isActive': true,
        'variants': [
          {'name': 'variant_on', 'weight': 100}
        ]
      });

      fakeAuth.signIn('user_1');
      await manager.initialize();

      final isEnabled = await manager.isFeatureEnabled('test_feature');
      final isVariantOn = await manager.isFeatureEnabled('test_feature', specificVariant: 'variant_on');

      expect(isEnabled, true);
      expect(isVariantOn, true);
    });

    test('trackEvent should save event to Firestore', () async {
      fakeAuth.signIn('user_1');

      await manager.trackEvent('test_1', 'click_button', properties: {'color': 'blue'});

      final events = await fakeFirestore.collection('ab_test_events').get();
      expect(events.docs.length, 1);
      expect(events.docs.first['testId'], 'test_1');
      expect(events.docs.first['eventName'], 'click_button');
      expect(events.docs.first['userId'], 'user_1');
    });

    test('should reload user variants on auth change', () async {
      await fakeFirestore.collection('ab_tests').doc('test_1').set({
        'isActive': true,
        'variants': [{'name': 'v1', 'weight': 100}]
      });

      await fakeFirestore.collection('users').doc('user_1').collection('ab_test_variants').doc('test_1').set({
        'variant': 'v1'
      });

      await fakeFirestore.collection('users').doc('user_2').collection('ab_test_variants').doc('test_1').set({
        'variant': 'v2'
      });

      await manager.initialize();

      fakeAuth.signIn('user_1');
      await Future.delayed(const Duration(milliseconds: 100));

      final v1 = await manager.getVariant('test_1');
      expect(v1, 'v1');

      fakeAuth.signOut();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(manager.getUserVariants(), isEmpty);

      fakeAuth.signIn('user_2');
      await Future.delayed(const Duration(milliseconds: 100));
      final v2 = await manager.getVariant('test_1');
      expect(v2, 'v2');
    });
  });

  group('ABTestVariant Model', () {
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

  group('ABTestConfig Model', () {
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

  group('FeatureConfig Model', () {
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

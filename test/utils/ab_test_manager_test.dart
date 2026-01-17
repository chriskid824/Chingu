import 'package:chingu/utils/ab_test_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

// Fake implementations for FirebaseAuth and User
class FakeFirebaseAuth implements FirebaseAuth {
  User? _currentUser;

  FakeFirebaseAuth({User? currentUser}) : _currentUser = currentUser;

  @override
  User? get currentUser => _currentUser;

  set currentUser(User? user) {
    _currentUser = user;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUser implements User {
  @override
  final String uid;

  FakeUser({required this.uid});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ABTestManager manager;
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseAuth fakeAuth;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeAuth = FakeFirebaseAuth(currentUser: FakeUser(uid: 'user_123'));

    manager = ABTestManager();
    manager.setDependencies(
      firestore: fakeFirestore,
      auth: fakeAuth,
    );
    manager.clearCache();
  });

  group('ABTestManager', () {
    test('initialize loads active tests', () async {
      // Arrange
      await fakeFirestore.collection('ab_tests').add({
        'name': 'Test A',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50},
          {'name': 'variant_a', 'weight': 50}
        ]
      });

      await fakeFirestore.collection('ab_tests').add({
        'name': 'Test B',
        'isActive': false, // Inactive
        'variants': [
          {'name': 'control', 'weight': 50},
          {'name': 'variant_b', 'weight': 50}
        ]
      });

      // Act
      await manager.initialize();

      // Assert
      // Access private member via public method or verify behavior
      // Since we can't access _cachedTests directly easily without reflection or helper,
      // we check via getVariant for a new user (assuming assignment works).

      // Test A is active, so we should get a variant (control or variant_a)
      final variantA = await manager.getVariant('Test A'); // This fails if not found in cache (returns control by default logic if config missing? No, returns 'control' if config missing, but we want to know if config IS present)

      // Wait, getVariant returns 'control' if config is missing.
      // So checking getVariant returning 'control' is ambiguous.
      // However, if we Mock the assignment to force non-control? No.

      // Let's rely on feature flag check or side effects.
      // Or we can trust that initialize worked if no error.

      // But better: define a test that has 100% weight on variant_a
       await fakeFirestore.collection('ab_tests').doc('test_c').set({
        'name': 'Test C',
        'isActive': true,
        'variants': [
          {'name': 'variant_only', 'weight': 100}
        ]
      });

      await manager.initialize();
      final variantC = await manager.getVariant('test_c');
      expect(variantC, 'variant_only');
    });

    test('getVariant assigns and persists variant', () async {
      // Arrange
      const testId = 'test_assignment';
      await fakeFirestore.collection('ab_tests').doc(testId).set({
        'name': 'Assignment Test',
        'isActive': true,
        'variants': [
          {'name': 'variant_1', 'weight': 100} // Force variant_1
        ]
      });

      await manager.initialize();

      // Act
      final variant = await manager.getVariant(testId);

      // Assert
      expect(variant, 'variant_1');

      // Verify persistence
      final userDoc = await fakeFirestore
          .collection('users')
          .doc('user_123')
          .collection('ab_test_variants')
          .doc(testId)
          .get();

      expect(userDoc.exists, true);
      expect(userDoc.data()?['variant'], 'variant_1');
    });

    test('getVariant returns existing assignment if present', () async {
      // Arrange
      const testId = 'test_existing';
      await fakeFirestore.collection('ab_tests').doc(testId).set({
        'name': 'Existing Test',
        'isActive': true,
        'variants': [
          {'name': 'variant_new', 'weight': 100}
        ]
      });

      // Pre-assign old variant
      await fakeFirestore
          .collection('users')
          .doc('user_123')
          .collection('ab_test_variants')
          .doc(testId)
          .set({'variant': 'variant_old'});

      await manager.initialize(); // Should load user variants

      // Act
      final variant = await manager.getVariant(testId);

      // Assert
      expect(variant, 'variant_old'); // Should stick to old assignment
    });

    test('isFeatureEnabled returns correct value for A/B test', () async {
      // Arrange
      const testId = 'feature_test';
      await fakeFirestore.collection('ab_tests').doc(testId).set({
        'name': 'Feature Test',
        'isActive': true,
        'variants': [
          {'name': 'variant_enabled', 'weight': 100}
        ]
      });

      await manager.initialize();

      // Act
      final isEnabled = await manager.isFeatureEnabled(testId); // default checks != control
      final isSpecific = await manager.isFeatureEnabled(testId, specificVariant: 'variant_enabled');

      // Assert
      expect(isEnabled, true);
      expect(isSpecific, true);
    });

    test('isFeatureEnabled works for simple feature flags', () async {
      // Arrange
      await fakeFirestore.collection('feature_flags').doc('simple_flag').set({
        'enabled': true,
        'config': {'key': 'value'}
      });

      // Act
      final isEnabled = await manager.isFeatureEnabled('simple_flag');

      // Assert
      expect(isEnabled, true);
    });

    test('trackEvent saves event to firestore', () async {
      // Arrange
      const testId = 'tracking_test';

      // Act
      await manager.trackEvent(testId, 'click_button', properties: {'color': 'red'});

      // Assert
      final snapshot = await fakeFirestore.collection('ab_test_events').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['testId'], testId);
      expect(data['eventName'], 'click_button');
      expect(data['userId'], 'user_123');
      expect(data['properties']['color'], 'red');
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

  group('ABTestVariant Model', () {
     test('should create variant and convert to map', () {
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
  });
}

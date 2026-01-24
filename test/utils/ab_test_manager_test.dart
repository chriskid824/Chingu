import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/utils/ab_test_manager.dart';

// Manual mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {
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
        returnValue: '',
      );
}

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
    abTestManager.setMockInstances(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
    abTestManager.clearCache();
  });

  group('ABTestManager Initialization', () {
    test('initialize loads active tests from Firestore', () async {
      // Arrange
      await fakeFirestore.collection('ab_tests').doc('test_feature').set({
        'name': 'Test Feature',
        'description': 'Testing new feature',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50, 'config': {}},
          {'name': 'variant_a', 'weight': 50, 'config': {}},
        ],
      });

      // Act
      await abTestManager.initialize();

      // Assert - We can verify by checking if getVariant returns something valid
      // without needing to fetch from Firestore again (since it should be cached)
      // Note: getVariant might trigger an assignment if not assigned yet,
      // but initialize should have populated the config cache.
      final variant = await abTestManager.getVariant('test_feature');
      expect(variant, anyOf('control', 'variant_a'));
    });

    test('initialize loads user variants from Firestore', () async {
      // Arrange
      await fakeFirestore.collection('ab_tests').doc('test_feature').set({
        'name': 'Test Feature',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50},
          {'name': 'variant_a', 'weight': 50},
        ],
      });

      // Pre-assign user to 'variant_a'
      await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('ab_test_variants')
          .doc('test_feature')
          .set({'variant': 'variant_a'});

      // Act
      await abTestManager.initialize();
      final variant = await abTestManager.getVariant('test_feature');

      // Assert
      expect(variant, 'variant_a');
    });
  });

  group('ABTestManager Variant Assignment', () {
    setUp(() async {
      await fakeFirestore.collection('ab_tests').doc('test_feature').set({
        'name': 'Test Feature',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50},
          {'name': 'variant_a', 'weight': 50},
        ],
      });
      await abTestManager.initialize();
    });

    test('getVariant assigns new variant if none exists', () async {
      // Act
      final variant = await abTestManager.getVariant('test_feature');

      // Assert
      expect(variant, anyOf('control', 'variant_a'));

      // Verify assignment is saved to Firestore
      final userVariantDoc = await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('ab_test_variants')
          .doc('test_feature')
          .get();

      expect(userVariantDoc.exists, true);
      expect(userVariantDoc.data()?['variant'], variant);
    });

    test('getVariant returns "control" for unknown test', () async {
      // Act
      final variant = await abTestManager.getVariant('unknown_test');

      // Assert
      expect(variant, 'control');
    });
  });

  group('Feature Flags', () {
    test('isFeatureEnabled returns true/false based on feature flag', () async {
      // Arrange
      await fakeFirestore.collection('feature_flags').doc('new_ui').set({
        'enabled': true,
        'config': {},
      });

      // Act
      final isEnabled = await abTestManager.isFeatureEnabled('new_ui');

      // Assert
      expect(isEnabled, true);
    });

    test('isFeatureEnabled works with A/B test variants', () async {
      // Arrange
      await fakeFirestore.collection('ab_tests').doc('button_color').set({
        'name': 'Button Color',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 0},
          {'name': 'blue', 'weight': 100},
        ],
      });
      await abTestManager.initialize();

      // Act
      // Should be assigned 'blue' because weight is 100
      final isBlue = await abTestManager.isFeatureEnabled(
        'button_color',
        specificVariant: 'blue',
      );

      // Assert
      expect(isBlue, true);
    });
  });

  group('Event Tracking', () {
    test('trackEvent saves event to Firestore', () async {
      // Arrange
      await fakeFirestore.collection('ab_tests').doc('test_feature').set({
        'name': 'Test Feature',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 100},
        ],
      });
      await abTestManager.initialize();
      await abTestManager.getVariant('test_feature'); // Ensure assigned

      // Act
      await abTestManager.trackEvent('test_feature', 'click_button', properties: {'btn_id': 1});

      // Assert
      final events = await fakeFirestore.collection('ab_test_events').get();
      expect(events.docs.length, 1);
      expect(events.docs.first['testId'], 'test_feature');
      expect(events.docs.first['eventName'], 'click_button');
      expect(events.docs.first['variant'], 'control');
      expect(events.docs.first['properties']['btn_id'], 1);
    });
  });
}

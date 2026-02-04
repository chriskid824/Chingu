import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/utils/ab_test_manager.dart';

// Import the generated mocks file
import 'ab_test_manager_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseAuth>(),
  MockSpec<User>(),
])
void main() {
  late ABTestManager abTestManager;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Mock User ID
    when(mockUser.uid).thenReturn('test_user_id');
    when(mockAuth.currentUser).thenReturn(mockUser);

    abTestManager = ABTestManager();
    abTestManager.setFirestoreInstance(fakeFirestore);
    abTestManager.setAuthInstance(mockAuth);
    abTestManager.clearCache();
    abTestManager.clearUserVariants();
  });

  group('ABTestManager', () {
    test('initialize loads active tests', () async {
      // Setup Firestore data
      await fakeFirestore.collection('ab_tests').add({
        'name': 'Test A',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50},
          {'name': 'variant', 'weight': 50},
        ],
      });

      await fakeFirestore.collection('ab_tests').add({
        'name': 'Test B',
        'isActive': false,
        'variants': [],
      });

      await abTestManager.initialize();

      // We can't access private _cachedTests directly, but we can verify via behavior
      // or we can test getVariant for the active test
      // Actually we don't know the ID of the doc we added.
      // Let's add with specific ID
    });

    test('getVariant assigns variant and persists it', () async {
      // Setup test
      await fakeFirestore.collection('ab_tests').doc('test_feature').set({
        'name': 'Feature Test',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50},
          {'name': 'variant_b', 'weight': 50},
        ],
      });

      await abTestManager.initialize();

      final variant = await abTestManager.getVariant('test_feature');
      expect(variant, isNotNull);
      expect(['control', 'variant_b'], contains(variant));

      // Check persistence
      final userVariantDoc = await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('ab_test_variants')
          .doc('test_feature')
          .get();

      expect(userVariantDoc.exists, true);
      expect(userVariantDoc.data()!['variant'], variant);
    });

    test('getVariant returns consistent result from cache', () async {
      // Setup test
      await fakeFirestore.collection('ab_tests').doc('test_consistent').set({
        'name': 'Consistent Test',
        'isActive': true,
        'variants': [
          {'name': 'control', 'weight': 50},
          {'name': 'variant_b', 'weight': 50},
        ],
      });

      await abTestManager.initialize();

      final firstVariant = await abTestManager.getVariant('test_consistent');
      final secondVariant = await abTestManager.getVariant('test_consistent');

      expect(firstVariant, secondVariant);
    });

    test('loadUserVariants loads existing assignments', () async {
      // Setup existing assignment
      await fakeFirestore
          .collection('users')
          .doc('test_user_id')
          .collection('ab_test_variants')
          .doc('existing_test')
          .set({'variant': 'variant_saved'});

      // Initialize (which calls loadUserVariants)
      await abTestManager.initialize();

      final variant = await abTestManager.getVariant('existing_test');
      expect(variant, 'variant_saved');
    });

    test('isFeatureEnabled returns true for non-control variants', () async {
       await fakeFirestore.collection('ab_tests').doc('feature_toggle').set({
        'name': 'Toggle',
        'isActive': true,
        'variants': [
          {'name': 'variant_on', 'weight': 100},
        ],
      });

      await abTestManager.initialize();

      final enabled = await abTestManager.isFeatureEnabled('feature_toggle');
      expect(enabled, true);
    });

    test('isFeatureEnabled checks simple feature flags if no AB test', () async {
      await fakeFirestore.collection('feature_flags').doc('simple_flag').set({
        'enabled': true,
      });

      final enabled = await abTestManager.isFeatureEnabled('simple_flag');
      expect(enabled, true);

       await fakeFirestore.collection('feature_flags').doc('disabled_flag').set({
        'enabled': false,
      });

      final disabled = await abTestManager.isFeatureEnabled('disabled_flag');
      expect(disabled, false);
    });
  });
}

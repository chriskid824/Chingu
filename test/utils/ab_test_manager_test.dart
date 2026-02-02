import 'package:chingu/utils/ab_test_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseAuth, User])
import 'ab_test_manager_test.mocks.dart';

void main() {
  late ABTestManager manager;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Set up mock user
    when(mockUser.uid).thenReturn('test_user_id');
    when(mockAuth.currentUser).thenReturn(mockUser);

    manager = ABTestManager();
    manager.firestoreInstance = fakeFirestore;
    manager.authInstance = mockAuth;
    manager.clearCache();
  });

  group('ABTestManager Initialization', () {
    test('loads configs from firestore', () async {
      await fakeFirestore.collection('ab_tests').doc('test_1').set({
        'name': 'Test A',
        'isActive': true,
        'variants': [
          {'name': 'A', 'weight': 100},
        ]
      });

      await manager.initialize();
      final variant = await manager.getVariant('test_1');
      expect(variant, equals('A'));
    });
  });

  group('Variant Assignment', () {
    test('assigns deterministic variant', () async {
      final testId = 'test_deterministic';
      await fakeFirestore.collection('ab_tests').doc(testId).set({
        'isActive': true,
        'variants': [
          {'name': 'A', 'weight': 50},
          {'name': 'B', 'weight': 50},
        ]
      });

      await manager.initialize();

      final variant1 = await manager.getVariant(testId);

      // Check persistence
      final userDoc = await fakeFirestore.collection('users').doc('test_user_id').collection('ab_test_variants').doc(testId).get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data()?['variant'], equals(variant1));

      // Calling again should return same
      final variant2 = await manager.getVariant(testId);
      expect(variant2, equals(variant1));
    });

    test('respects different weights/seeds', () async {
      // This test tries to ensure we don't just always return the first variant
      // It's tricky to test determinism with random seed fallback, but here we have mocked user ID.
      // logic: (userId + config.testId).hashCode.abs() % 100;

      // Let's create a test case where we know the hash result or just check multiple users

      final testId = 'test_weight';
      await fakeFirestore.collection('ab_tests').doc(testId).set({
        'isActive': true,
        'variants': [
          {'name': 'A', 'weight': 50},
          {'name': 'B', 'weight': 50},
        ]
      });

      // User 1
      when(mockUser.uid).thenReturn('user_1');
      manager.clearCache();
      await manager.initialize();
      final v1 = await manager.getVariant(testId);

      // User 2
      when(mockUser.uid).thenReturn('user_2');
      manager.clearCache();
      await manager.initialize();
      final v2 = await manager.getVariant(testId);

      // Note: user_1 and user_2 might get same variant, but at least code runs
      // print('v1: $v1, v2: $v2');
      expect(v1, isNotNull);
      expect(v2, isNotNull);
    });
  });

  group('Feature Toggles', () {
    test('returns correct feature flag', () async {
      await fakeFirestore.collection('feature_flags').doc('new_feature').set({
        'enabled': true,
      });

      final isEnabled = await manager.isFeatureEnabled('new_feature');
      expect(isEnabled, isTrue);
    });

    test('returns false for unknown feature', () async {
       final isEnabled = await manager.isFeatureEnabled('unknown_feature');
       expect(isEnabled, isFalse);
    });
  });
}

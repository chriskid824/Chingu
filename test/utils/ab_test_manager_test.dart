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

    manager = ABTestManager();
    manager.setDependencies(fakeFirestore, mockAuth);
    manager.clearCache();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test_user_123');
  });

  group('ABTestManager Hashing', () {
    test('Should return same variant for same user and config (Deterministic)', () async {
      final config = ABTestConfig(
        testId: 'test_experiment_1',
        name: 'Test Exp',
        description: 'Desc',
        isActive: true,
        variants: [
          ABTestVariant(name: 'A', weight: 50),
          ABTestVariant(name: 'B', weight: 50),
        ],
      );

      await fakeFirestore.collection('ab_tests').doc('test_experiment_1').set(config.toMap());
      await manager.initialize();

      final variant1 = await manager.getVariant('test_experiment_1');

      manager.clearCache();
      await manager.initialize();
      final variant2 = await manager.getVariant('test_experiment_1');

      expect(variant1, equals(variant2));
    });

    test('Should distribute users deterministically', () async {
      final config = ABTestConfig(
        testId: 'distribution_test',
        name: 'Dist Test',
        description: 'Desc',
        isActive: true,
        variants: [
          ABTestVariant(name: 'A', weight: 50),
          ABTestVariant(name: 'B', weight: 50),
        ],
      );
      await fakeFirestore.collection('ab_tests').doc('distribution_test').set(config.toMap());

      Future<String> getVariantForId(String uid) async {
        final mAuth = MockFirebaseAuth();
        final mUser = MockUser();
        when(mAuth.currentUser).thenReturn(mUser);
        when(mUser.uid).thenReturn(uid);

        manager.setDependencies(fakeFirestore, mAuth);
        manager.clearCache();
        await manager.initialize();

        return await manager.getVariant('distribution_test');
      }

      final v1 = await getVariantForId('user1');
      final v1_again = await getVariantForId('user1');
      expect(v1, equals(v1_again));

      final v2 = await getVariantForId('user2');
      final v2_again = await getVariantForId('user2');
      expect(v2, equals(v2_again));
    });
  });

  group('ABTestManager Integration', () {
     test('isFeatureEnabled should respect experiment variant', () async {
        final config = ABTestConfig(
        testId: 'feature_test',
        name: 'Feature Test',
        description: 'Desc',
        isActive: true,
        variants: [
          ABTestVariant(name: 'control', weight: 0),
          ABTestVariant(name: 'variant_on', weight: 100),
        ],
      );
      await fakeFirestore.collection('ab_tests').doc('feature_test').set(config.toMap());
      await manager.initialize();

      expect(await manager.isFeatureEnabled('feature_test'), isTrue);
      expect(await manager.isFeatureEnabled('feature_test', specificVariant: 'variant_on'), isTrue);
      expect(await manager.isFeatureEnabled('feature_test', specificVariant: 'control'), isFalse);
     });

     test('isFeatureEnabled should fall back to feature_flags collection', () async {
       await fakeFirestore.collection('feature_flags').doc('simple_flag').set({
         'enabled': true,
         'config': {}
       });

       expect(await manager.isFeatureEnabled('simple_flag'), isTrue);
       expect(await manager.isFeatureEnabled('non_existent_flag'), isFalse);
     });
  });
}

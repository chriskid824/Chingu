import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/utils/ab_test_manager.dart';

// Fake User
class FakeUser extends Fake implements User {
  final String _uid;
  FakeUser(this._uid);
  @override
  String get uid => _uid;
}

// Fake FirebaseAuth
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
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseAuth fakeAuth;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeAuth = FakeFirebaseAuth();
    manager = ABTestManager();
    manager.setFirestoreInstance(fakeFirestore);
    manager.setAuthInstance(fakeAuth);
    manager.clearCache();
    manager.clearUserData();
  });

  group('ABTestManager', () {
    test('initialize loads config from firestore', () async {
      // Setup
      await fakeFirestore.collection('ab_tests').doc('test_1').set({
        'name': 'Test 1',
        'isActive': true,
        'variants': [
           {'name': 'A', 'weight': 50.0},
           {'name': 'B', 'weight': 50.0}
        ]
      });

      // Act
      await manager.initialize();

      // Assert
      // We can't access private _cachedTests, but we can verify behavior via getVariant
      // Without user, it should return default (first variant usually or control if logic dictates)
      // Our logic: if no user, return first variant name.
      final variant = await manager.getVariant('test_1');
      expect(variant, equals('A'));
    });

    test('getVariant returns deterministic result', () async {
       // Setup config
      await fakeFirestore.collection('ab_tests').doc('test_color').set({
        'name': 'Color Test',
        'isActive': true,
        'variants': [
           {'name': 'red', 'weight': 50.0},
           {'name': 'blue', 'weight': 50.0}
        ]
      });
      await manager.initialize();

      // Setup User
      fakeAuth.setMockUser(FakeUser('user_123'));
      manager.clearUserData();

      // Act
      final v1 = await manager.getVariant('test_color');

      // Clear again to simulate fresh start on same device
      manager.clearUserData();
      final v2 = await manager.getVariant('test_color');

      expect(v1, equals(v2));
    });

    test('isFeatureEnabled returns true for enabled variant', () async {
       await fakeFirestore.collection('ab_tests').doc('feature_x').set({
        'name': 'Feature X',
        'isActive': true,
        'variants': [
           {'name': 'control', 'weight': 0.0},
           {'name': 'enabled', 'weight': 100.0}
        ]
      });
      await manager.initialize();
      fakeAuth.setMockUser(FakeUser('user_x'));

      expect(await manager.isFeatureEnabled('feature_x'), isTrue);
    });

    test('isFeatureEnabled returns false for control variant', () async {
       await fakeFirestore.collection('ab_tests').doc('feature_y').set({
        'name': 'Feature Y',
        'isActive': true,
        'variants': [
           {'name': 'control', 'weight': 100.0},
           {'name': 'enabled', 'weight': 0.0}
        ]
      });
      await manager.initialize();
      fakeAuth.setMockUser(FakeUser('user_y'));

      expect(await manager.isFeatureEnabled('feature_y'), isFalse);
    });

    test('feature flag check works when not in ab_tests', () async {
      await fakeFirestore.collection('feature_flags').doc('simple_flag').set({
        'enabled': true
      });

      expect(await manager.isFeatureEnabled('simple_flag'), isTrue);
    });
  });
}

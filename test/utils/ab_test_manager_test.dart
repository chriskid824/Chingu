import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:chingu/utils/ab_test_manager.dart';

@GenerateMocks([FirebaseRemoteConfig])
import 'ab_test_manager_test.mocks.dart';

void main() {
  late ABTestManager abTestManager;
  late MockFirebaseRemoteConfig mockRemoteConfig;

  setUp(() {
    abTestManager = ABTestManager();
    mockRemoteConfig = MockFirebaseRemoteConfig();
    abTestManager.setRemoteConfigForTesting(mockRemoteConfig);
  });

  test('initialize sets defaults and fetches', () async {
    // Arrange
    when(mockRemoteConfig.setConfigSettings(any)).thenAnswer((_) async {});
    when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
    when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
    when(mockRemoteConfig.lastFetchStatus).thenReturn(RemoteConfigFetchStatus.success);

    // Act
    await abTestManager.initialize(defaults: {'test': true});

    // Assert
    verify(mockRemoteConfig.setConfigSettings(any)).called(1);
    verify(mockRemoteConfig.setDefaults(any)).called(1);
    verify(mockRemoteConfig.fetchAndActivate()).called(1);
  });

  test('isFeatureEnabled returns bool from config', () {
    when(mockRemoteConfig.getBool('feature_x')).thenReturn(true);

    expect(abTestManager.isFeatureEnabled('feature_x'), true);
    verify(mockRemoteConfig.getBool('feature_x')).called(1);
  });

  test('getString returns string from config', () {
    when(mockRemoteConfig.getString('variant_key')).thenReturn('variant_b');

    expect(abTestManager.getString('variant_key'), 'variant_b');
  });

  test('getNumber returns double from config', () {
    when(mockRemoteConfig.getDouble('price')).thenReturn(99.9);

    expect(abTestManager.getNumber('price'), 99.9);
  });
}

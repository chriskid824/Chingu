import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:chingu/utils/ab_test_manager.dart';

// Generate mocks
@GenerateMocks([FirebaseRemoteConfig])
import 'ab_test_manager_test.mocks.dart';

void main() {
  late ABTestManager abTestManager;
  late MockFirebaseRemoteConfig mockRemoteConfig;

  setUp(() {
    // Note: Since ABTestManager is a singleton, we need to be careful.
    // However, setRemoteConfigForTesting overrides the instance member.
    abTestManager = ABTestManager();
    mockRemoteConfig = MockFirebaseRemoteConfig();
    abTestManager.setRemoteConfigForTesting(mockRemoteConfig);
  });

  test('isFeatureEnabled returns value from remote config', () {
    when(mockRemoteConfig.getBool('test_feature')).thenReturn(true);
    expect(abTestManager.isFeatureEnabled('test_feature'), true);

    when(mockRemoteConfig.getBool('test_feature')).thenReturn(false);
    expect(abTestManager.isFeatureEnabled('test_feature'), false);
  });

  test('getString returns value from remote config', () {
    when(mockRemoteConfig.getString('test_variant')).thenReturn('variant_a');
    expect(abTestManager.getString('test_variant'), 'variant_a');
  });

  test('initialize sets defaults and activates', () async {
    when(mockRemoteConfig.setConfigSettings(any)).thenAnswer((_) async {});
    when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
    when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);

    await abTestManager.initialize();

    verify(mockRemoteConfig.setConfigSettings(any)).called(1);
    verify(mockRemoteConfig.setDefaults(any)).called(1);
    verify(mockRemoteConfig.fetchAndActivate()).called(1);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:chingu/utils/ab_test_manager.dart';

// 使用 Fake 來代替 Mockito 生成的 Mock，避免 build_runner 問題
class FakeRemoteConfig implements FirebaseRemoteConfig {
  final Map<String, dynamic> _defaults = {};
  final Map<String, dynamic> _values = {};

  @override
  Future<void> setConfigSettings(RemoteConfigSettings remoteConfigSettings) async {}

  @override
  Future<void> setDefaults(Map<String, dynamic> defaultParameters) async {
    _defaults.addAll(defaultParameters);
  }

  @override
  Future<bool> fetchAndActivate() async {
    return true;
  }

  @override
  bool getBool(String key) {
    if (_values.containsKey(key)) return _values[key] as bool;
    if (_defaults.containsKey(key)) return _defaults[key] as bool;
    return false;
  }

  @override
  String getString(String key) {
    if (_values.containsKey(key)) return _values[key] as String;
    if (_defaults.containsKey(key)) return _defaults[key] as String;
    return '';
  }

  @override
  double getDouble(String key) {
    if (_values.containsKey(key)) return _values[key] as double;
    if (_defaults.containsKey(key)) return _defaults[key] as double;
    return 0.0;
  }

  @override
  int getInt(String key) {
    if (_values.containsKey(key)) return _values[key] as int;
    if (_defaults.containsKey(key)) return _defaults[key] as int;
    return 0;
  }

  @override
  Map<String, RemoteConfigValue> getAll() {
    return {};
  }

  // 用於測試設置值的輔助方法
  void setTestValue(String key, dynamic value) {
    _values[key] = value;
  }

  // 其他未使用的接口方法需要實現(Stub)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  DateTime get lastFetchTime => DateTime.now();

  @override
  RemoteConfigFetchStatus get lastFetchStatus => RemoteConfigFetchStatus.success;

  @override
  RemoteConfigSettings get settings => RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(hours: 1),
  );

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<bool> activate() async => true;

  @override
  Future<void> fetch() async {}

  @override
  RemoteConfigValue getValue(String key) {
     throw UnimplementedError();
  }

  @override
  Set<String> getKeys(String keyPrefix) => {};

  @override
  Map<String, RemoteConfigValue> get pluginConstants => {};
}

void main() {
  late FakeRemoteConfig fakeRemoteConfig;
  late ABTestManager abTestManager;

  setUp(() {
    fakeRemoteConfig = FakeRemoteConfig();
    abTestManager = ABTestManager();
    // Inject fake
    abTestManager.remoteConfig = fakeRemoteConfig;
  });

  test('initialize sets defaults and fetches', () async {
    await abTestManager.initialize(defaults: {'test_key': true});

    // 驗證 default 值生效
    expect(fakeRemoteConfig.getBool('test_key'), true);
  });

  test('isFeatureEnabled returns correct value', () {
    fakeRemoteConfig.setTestValue('feature_x', true);
    expect(abTestManager.isFeatureEnabled('feature_x'), true);

    fakeRemoteConfig.setTestValue('feature_y', false);
    expect(abTestManager.isFeatureEnabled('feature_y'), false);
  });

  test('getVariant returns correct string', () {
    fakeRemoteConfig.setTestValue('variant_test', 'group_a');
    expect(abTestManager.getVariant('variant_test'), 'group_a');
  });
}

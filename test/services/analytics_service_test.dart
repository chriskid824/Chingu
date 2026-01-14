import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/analytics_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FakeFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  final List<String> logs = [];

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    logs.add('logEvent: $name, parameters: $parameters');
  }

  @override
  Future<void> logScreenView({
    String? screenClass,
    String? screenName,
    AnalyticsCallOptions? callOptions,
  }) async {
    logs.add('logScreenView: $screenName, class: $screenClass');
  }

  @override
  Future<void> setUserId({
    String? id,
    AnalyticsCallOptions? callOptions,
  }) async {
    logs.add('setUserId: $id');
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
    AnalyticsCallOptions? callOptions,
  }) async {
    logs.add('setUserProperty: $name, value: $value');
  }
}

void main() {
  late AnalyticsService analyticsService;
  late FakeFirebaseAnalytics fakeAnalytics;

  setUp(() {
    fakeAnalytics = FakeFirebaseAnalytics();
    analyticsService = AnalyticsService(analytics: fakeAnalytics);
  });

  test('logEvent calls FirebaseAnalytics.logEvent', () async {
    await analyticsService.logEvent(name: 'test_event', parameters: {'key': 'value'});
    expect(fakeAnalytics.logs, contains('logEvent: test_event, parameters: {key: value}'));
  });

  test('logScreenView calls FirebaseAnalytics.logScreenView', () async {
    await analyticsService.logScreenView(screenName: 'TestScreen');
    expect(fakeAnalytics.logs, contains('logScreenView: TestScreen, class: null'));
  });

  test('setUserId calls FirebaseAnalytics.setUserId', () async {
    await analyticsService.setUserId('user_123');
    expect(fakeAnalytics.logs, contains('setUserId: user_123'));
  });

  test('setUserProperty calls FirebaseAnalytics.setUserProperty', () async {
    await analyticsService.setUserProperty(name: 'role', value: 'admin');
    expect(fakeAnalytics.logs, contains('setUserProperty: role, value: admin'));
  });
}

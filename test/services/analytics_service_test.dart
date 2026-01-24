import 'package:chingu/services/analytics_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'analytics_service_test.mocks.dart';

@GenerateMocks([FirebaseAnalytics])
void main() {
  late AnalyticsService analyticsService;
  late MockFirebaseAnalytics mockAnalytics;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    analyticsService = AnalyticsService();
    analyticsService.setMockInstance(mockAnalytics);
  });

  test('logEvent calls FirebaseAnalytics.logEvent', () async {
    await analyticsService.logEvent(name: 'test_event', parameters: {'param': 'value'});
    verify(mockAnalytics.logEvent(name: 'test_event', parameters: {'param': 'value'})).called(1);
  });

  test('logScreenView calls FirebaseAnalytics.logScreenView', () async {
    await analyticsService.logScreenView(screenName: 'TestScreen', screenClass: 'TestClass');
    verify(mockAnalytics.logScreenView(screenName: 'TestScreen', screenClass: 'TestClass')).called(1);
  });

  test('setUserId calls FirebaseAnalytics.setUserId', () async {
    await analyticsService.setUserId('user123');
    verify(mockAnalytics.setUserId(id: 'user123')).called(1);
  });

  test('setUserProperty calls FirebaseAnalytics.setUserProperty', () async {
    await analyticsService.setUserProperty(name: 'prop', value: 'val');
    verify(mockAnalytics.setUserProperty(name: 'prop', value: 'val')).called(1);
  });

  test('logLogin calls FirebaseAnalytics.logLogin', () async {
    await analyticsService.logLogin(method: 'email');
    verify(mockAnalytics.logLogin(loginMethod: 'email')).called(1);
  });

  test('logSignUp calls FirebaseAnalytics.logSignUp', () async {
    await analyticsService.logSignUp(signUpMethod: 'google');
    verify(mockAnalytics.logSignUp(signUpMethod: 'google')).called(1);
  });
}

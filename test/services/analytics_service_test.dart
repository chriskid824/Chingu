import 'package:chingu/services/analytics_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseAnalytics])
import 'analytics_service_test.mocks.dart';

void main() {
  late AnalyticsService analyticsService;
  late MockFirebaseAnalytics mockAnalytics;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    analyticsService = AnalyticsService(analytics: mockAnalytics);
  });

  test('logEvent calls firebase analytics', () async {
    await analyticsService.logEvent(name: 'test_event', parameters: {'p1': 'v1'});
    verify(mockAnalytics.logEvent(name: 'test_event', parameters: {'p1': 'v1'})).called(1);
  });

  test('logScreenView calls firebase analytics', () async {
    await analyticsService.logScreenView(screenName: 'TestScreen', screenClass: 'TestClass');
    verify(mockAnalytics.logScreenView(screenName: 'TestScreen', screenClass: 'TestClass')).called(1);
  });

  test('logLogin calls firebase analytics', () async {
    await analyticsService.logLogin(method: 'email');
    verify(mockAnalytics.logLogin(loginMethod: 'email')).called(1);
  });

  test('logSignUp calls firebase analytics', () async {
    await analyticsService.logSignUp(method: 'email');
    verify(mockAnalytics.logSignUp(signUpMethod: 'email')).called(1);
  });

  test('setUserProperty calls firebase analytics', () async {
    await analyticsService.setUserProperty(name: 'age', value: '25');
    verify(mockAnalytics.setUserProperty(name: 'age', value: '25')).called(1);
  });
}

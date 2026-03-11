import 'package:chingu/services/analytics_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseAnalytics])
import 'analytics_service_test.mocks.dart';

void main() {
  late AnalyticsService service;
  late MockFirebaseAnalytics mockAnalytics;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    service = AnalyticsService();
    // Inject the mock
    service.analytics = mockAnalytics;
  });

  group('AnalyticsService', () {
    test('logEvent calls underlying analytics', () async {
      await service.logEvent('test_event', parameters: {'param': 'value'});
      verify(mockAnalytics.logEvent(name: 'test_event', parameters: {'param': 'value'})).called(1);
    });

    test('setUserId calls underlying analytics', () async {
      await service.setUserId('user123');
      verify(mockAnalytics.setUserId(id: 'user123')).called(1);
    });

    test('setUserProperty calls underlying analytics', () async {
      await service.setUserProperty(name: 'role', value: 'admin');
      verify(mockAnalytics.setUserProperty(name: 'role', value: 'admin')).called(1);
    });

    test('logScreenView calls underlying analytics', () async {
      await service.logScreenView(screenName: 'Home', screenClass: 'HomeScreen');
      verify(mockAnalytics.logScreenView(screenName: 'Home', screenClass: 'HomeScreen')).called(1);
    });

    test('logLogin calls underlying analytics', () async {
      await service.logLogin(method: 'email');
      verify(mockAnalytics.logLogin(loginMethod: 'email')).called(1);
    });

    test('logSignUp calls underlying analytics', () async {
      await service.logSignUp(method: 'google');
      verify(mockAnalytics.logSignUp(signUpMethod: 'google')).called(1);
    });

    test('logTutorialBegin calls underlying analytics', () async {
      await service.logTutorialBegin();
      verify(mockAnalytics.logTutorialBegin()).called(1);
    });

    test('logTutorialComplete calls underlying analytics', () async {
      await service.logTutorialComplete();
      verify(mockAnalytics.logTutorialComplete()).called(1);
    });
  });
}

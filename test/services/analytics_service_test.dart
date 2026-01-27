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
    analyticsService = AnalyticsService();
    mockAnalytics = MockFirebaseAnalytics();
    analyticsService.setAnalyticsForTest(mockAnalytics);
  });

  group('AnalyticsService', () {
    test('logEvent calls logEvent on FirebaseAnalytics', () async {
      const eventName = 'test_event';
      const parameters = {'param': 'value'};

      await analyticsService.logEvent(name: eventName, parameters: parameters);

      verify(mockAnalytics.logEvent(name: eventName, parameters: parameters)).called(1);
    });

    test('setUserId calls setUserId on FirebaseAnalytics', () async {
      const userId = 'user_123';

      await analyticsService.setUserId(userId);

      verify(mockAnalytics.setUserId(id: userId)).called(1);
    });

    test('setUserProperty calls setUserProperty on FirebaseAnalytics', () async {
      const name = 'user_type';
      const value = 'premium';

      await analyticsService.setUserProperty(name: name, value: value);

      verify(mockAnalytics.setUserProperty(name: name, value: value)).called(1);
    });

    test('logScreenView calls logScreenView on FirebaseAnalytics', () async {
      const screenName = 'HomeScreen';
      const screenClass = 'HomeScreenClass';

      await analyticsService.logScreenView(screenName: screenName, screenClass: screenClass);

      verify(mockAnalytics.logScreenView(screenName: screenName, screenClass: screenClass)).called(1);
    });

    test('getAnalyticsObserver returns an observer', () {
      final observer = analyticsService.getAnalyticsObserver();
      expect(observer, isA<FirebaseAnalyticsObserver>());
    });
  });
}

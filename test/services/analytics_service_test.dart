import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:chingu/services/analytics_service.dart';

// Generate mocks
@GenerateMocks([FirebaseAnalytics])
import 'analytics_service_test.mocks.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;
    late MockFirebaseAnalytics mockAnalytics;

    setUp(() {
      analyticsService = AnalyticsService();
      mockAnalytics = MockFirebaseAnalytics();
      analyticsService.analytics = mockAnalytics;
    });

    test('logEvent calls FirebaseAnalytics.logEvent', () async {
      when(mockAnalytics.logEvent(
        name: anyNamed('name'),
        parameters: anyNamed('parameters'),
      )).thenAnswer((_) async {});

      await analyticsService.logEvent(
        name: 'test_event',
        parameters: {'param': 'value'},
      );

      verify(mockAnalytics.logEvent(
        name: 'test_event',
        parameters: {'param': 'value'},
      )).called(1);
    });

    test('logScreenView calls FirebaseAnalytics.logScreenView', () async {
      when(mockAnalytics.logScreenView(
        screenName: anyNamed('screenName'),
        screenClass: anyNamed('screenClass'),
      )).thenAnswer((_) async {});

      await analyticsService.logScreenView(
        screenName: 'TestScreen',
        screenClass: 'TestClass',
      );

      verify(mockAnalytics.logScreenView(
        screenName: 'TestScreen',
        screenClass: 'TestClass',
      )).called(1);
    });

    test('setUserId calls FirebaseAnalytics.setUserId', () async {
      when(mockAnalytics.setUserId(id: anyNamed('id')))
          .thenAnswer((_) async {});

      await analyticsService.setUserId('user123');

      verify(mockAnalytics.setUserId(id: 'user123')).called(1);
    });

    test('setUserProperty calls FirebaseAnalytics.setUserProperty', () async {
      when(mockAnalytics.setUserProperty(
        name: anyNamed('name'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      await analyticsService.setUserProperty(name: 'role', value: 'admin');

      verify(mockAnalytics.setUserProperty(name: 'role', value: 'admin')).called(1);
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:chingu/services/analytics_service.dart';

// Generate Mocks
@GenerateMocks([FirebaseAnalytics, FirebaseAnalyticsObserver])
import 'analytics_service_test.mocks.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;
    late MockFirebaseAnalytics mockAnalytics;

    // Note: Since AnalyticsService is a singleton and initializes FirebaseAnalytics.instance internally
    // without dependency injection support in the current implementation,
    // it's hard to fully unit test it without refactoring the service to accept an instance.
    // However, we can verify that the class structure is correct.

    test('is a singleton', () {
      final s1 = AnalyticsService();
      final s2 = AnalyticsService();
      expect(s1, equals(s2));
    });

    // Ideally we would test calls like this:
    // test('logEvent calls FirebaseAnalytics.logEvent', () async {
    //   await analyticsService.logEvent(name: 'test_event');
    //   verify(mockAnalytics.logEvent(name: 'test_event')).called(1);
    // });
    // But we need to refactor AnalyticsService to allow injecting the mock.
  });
}

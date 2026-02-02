import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:chingu/services/analytics_service.dart';

@GenerateNiceMocks([MockSpec<FirebaseAnalytics>()])
import 'analytics_service_test.mocks.dart';

void main() {
  late AnalyticsService analyticsService;
  late MockFirebaseAnalytics mockAnalytics;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    analyticsService = AnalyticsService();
    analyticsService.analytics = mockAnalytics;
  });

  group('AnalyticsService', () {
    test('logEvent calls FirebaseAnalytics.logEvent', () async {
      await analyticsService.logEvent('test_event', {'param': 'value'});
      verify(mockAnalytics.logEvent(name: 'test_event', parameters: {'param': 'value'})).called(1);
    });

    test('logNotificationReceived logs correct event and params', () async {
      await analyticsService.logNotificationReceived(
        notificationId: '123',
        variant: 'control',
      );

      verify(mockAnalytics.logEvent(
        name: 'notification_received',
        parameters: {
          'notification_id': '123',
          'variant': 'control',
        },
      )).called(1);
    });

    test('logNotificationClicked logs correct event and params', () async {
      await analyticsService.logNotificationClicked(
        notificationId: '123',
        variant: 'variant_b',
        actionId: 'open',
      );

      verify(mockAnalytics.logEvent(
        name: 'notification_clicked',
        parameters: {
          'notification_id': '123',
          'variant': 'variant_b',
          'action_id': 'open',
        },
      )).called(1);
    });
  });
}

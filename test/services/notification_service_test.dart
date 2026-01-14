import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/notification_service.dart';
import 'package:chingu/services/analytics_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/services/notification_ab_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:mockito/mockito.dart';

// Manual Mocks
class MockAnalyticsService extends Mock implements AnalyticsService {
  @override
  Future<void> logNotificationSent({
    required String notificationId,
    required String type,
    required String group,
  }) async {
    return super.noSuchMethod(
      Invocation.method(#logNotificationSent, [], {
        #notificationId: notificationId,
        #type: type,
        #group: group,
      }),
      returnValue: Future.value(),
    );
  }
}

class MockRichNotificationService extends Mock implements RichNotificationService {
  @override
  Future<void> showNotification(NotificationModel? notification) async {
    return super.noSuchMethod(
      Invocation.method(#showNotification, [notification]),
      returnValue: Future.value(),
    );
  }
}

class MockNotificationABService extends Mock implements NotificationABService {
  @override
  ExperimentGroup getGroup(String? userId) {
    return super.noSuchMethod(
      Invocation.method(#getGroup, [userId]),
      returnValue: ExperimentGroup.control,
    );
  }

  @override
  NotificationContent getContent(
    String? userId,
    NotificationType? type,
    {Map<String, dynamic>? params}
  ) {
    return super.noSuchMethod(
      Invocation.method(#getContent, [userId, type], {#params: params}),
      returnValue: NotificationContent(title: 'Test', body: 'Body'),
    );
  }
}

void main() {
  group('NotificationService', () {
    late NotificationService notificationService;
    late MockAnalyticsService mockAnalyticsService;
    late MockRichNotificationService mockRichNotificationService;
    late MockNotificationABService mockABService;

    setUp(() {
      notificationService = NotificationService();
      mockAnalyticsService = MockAnalyticsService();
      mockRichNotificationService = MockRichNotificationService();
      mockABService = MockNotificationABService();

      notificationService.setDependencies(
        analyticsService: mockAnalyticsService,
        richNotificationService: mockRichNotificationService,
        abService: mockABService,
      );
    });

    test('showNotification tracks sending and shows notification', () async {
      when(mockABService.getGroup(any)).thenReturn(ExperimentGroup.variant);
      when(mockABService.getContent(any, any, params: anyNamed('params')))
          .thenReturn(NotificationContent(title: 'Title', body: 'Body'));

      await notificationService.showNotification(
        userId: 'user1',
        type: NotificationType.match,
        params: {'partnerName': 'Alice'},
      );

      // Verify A/B service called
      verify(mockABService.getGroup('user1')).called(1);
      verify(mockABService.getContent('user1', NotificationType.match, params: anyNamed('params'))).called(1);

      // Verify notification shown
      final captured = verify(mockRichNotificationService.showNotification(captureAny)).captured;
      final notification = captured.first as NotificationModel;
      expect(notification.title, 'Title');
      expect(notification.message, 'Body');
      expect(notification.experimentGroup, 'variant');

      // Verify analytics logged
      verify(mockAnalyticsService.logNotificationSent(
        notificationId: anyNamed('notificationId'),
        type: 'match',
        group: 'variant',
      )).called(1);
    });
  });
}

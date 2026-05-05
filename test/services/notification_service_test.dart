import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/notification_service.dart';
import 'package:chingu/services/notification_ab_service.dart';
import 'package:chingu/services/analytics_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:mockito/mockito.dart';

// Manual Mocks
class MockNotificationABService extends Fake implements NotificationABService {
  @override
  ExperimentGroup getGroup(String userId) {
    return ExperimentGroup.variant;
  }

  @override
  NotificationContent getContent(String userId, NotificationType type, {Map<String, dynamic>? params}) {
    return NotificationContent(title: 'Mock Title', body: 'Mock Body');
  }
}

class MockAnalyticsService extends Fake implements AnalyticsService {
  String? lastEventName;
  Map<String, dynamic>? lastParams;

  @override
  Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    lastEventName = name;
    lastParams = parameters;
  }
}

class MockRichNotificationService extends Fake implements RichNotificationService {
  NotificationModel? lastNotification;

  @override
  Future<void> showNotification(NotificationModel notification) async {
    lastNotification = notification;
  }
}

class MockNotificationStorageService extends Fake implements NotificationStorageService {
  @override
  Future<String> saveNotification(NotificationModel notification) async {
    return 'mock_doc_id';
  }
}

void main() {
  late NotificationService notificationService;
  late MockNotificationABService mockABService;
  late MockAnalyticsService mockAnalyticsService;
  late MockRichNotificationService mockRichNotificationService;
  late MockNotificationStorageService mockStorageService;

  setUp(() {
    mockABService = MockNotificationABService();
    mockAnalyticsService = MockAnalyticsService();
    mockRichNotificationService = MockRichNotificationService();
    mockStorageService = MockNotificationStorageService();

    notificationService = NotificationService();
    notificationService.setDependencies(
      abService: mockABService,
      analytics: mockAnalyticsService,
      richNotificationService: mockRichNotificationService,
      storageService: mockStorageService,
    );
  });

  test('sendNotification logs event, saves to storage, and shows notification', () async {
    const userId = 'user_123';
    const type = NotificationType.match;

    await notificationService.sendNotification(
      userId: userId,
      type: type,
      params: {'partnerName': 'Alice'},
    );

    // Verify Analytics
    expect(mockAnalyticsService.lastEventName, 'notification_sent');
    expect(mockAnalyticsService.lastParams, isNotNull);
    expect(mockAnalyticsService.lastParams!['ab_group'], 'variant');
    expect(mockAnalyticsService.lastParams!['notification_type'], 'match');

    // Verify Storage and Show
    expect(mockRichNotificationService.lastNotification, isNotNull);
    expect(mockRichNotificationService.lastNotification!.id, 'mock_doc_id');
    expect(mockRichNotificationService.lastNotification!.title, 'Mock Title');
    expect(mockRichNotificationService.lastNotification!.trackingParams, isNotNull);
  });
}

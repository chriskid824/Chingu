import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'notification_ab_service.dart';
import 'rich_notification_service.dart';
import 'analytics_service.dart';

/// Service for tracking and managing notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  NotificationABService _abService = NotificationABService();
  RichNotificationService _richNotificationService = RichNotificationService();
  AnalyticsService _analyticsService = AnalyticsService();
  final Uuid _uuid = const Uuid();

  @visibleForTesting
  void setDependencies({
    NotificationABService? abService,
    RichNotificationService? richNotificationService,
    AnalyticsService? analyticsService,
  }) {
    if (abService != null) _abService = abService;
    if (richNotificationService != null) _richNotificationService = richNotificationService;
    if (analyticsService != null) _analyticsService = analyticsService;
  }

  /// Show a notification using A/B testing content and track the send event
  Future<void> showNotification({
    required String userId,
    required NotificationType type,
    Map<String, dynamic>? params,
    String? imageUrl,
    String? actionType,
    String? actionData,
  }) async {
    // Determine content based on A/B group
    final content = _abService.getContent(userId, type, params: params);
    final group = _abService.getGroup(userId);
    final groupName = group == ExperimentGroup.variant ? 'variant' : 'control';

    // Generate a unique ID for this notification instance
    final notificationId = _uuid.v4();

    // Create model
    final notification = NotificationModel(
      id: notificationId,
      userId: userId,
      type: type.toString().split('.').last, // 'match', 'message', etc.
      title: content.title,
      message: content.body,
      imageUrl: imageUrl,
      actionType: actionType,
      actionData: actionData,
      createdAt: DateTime.now(),
      experimentGroup: groupName,
    );

    // Show notification (local)
    await _richNotificationService.showNotification(notification);

    // Log sent event
    await _analyticsService.logNotificationSent(
      notificationId: notificationId,
      type: notification.type,
      group: groupName,
    );
  }
}

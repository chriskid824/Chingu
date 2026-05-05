import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'notification_ab_service.dart';
import 'analytics_service.dart';
import 'rich_notification_service.dart';
import 'notification_storage_service.dart';

/// Notification Coordinator Service
///
/// Coordinates the creation, storage, display, and tracking of notifications.
/// Integrates A/B testing for content generation.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  NotificationABService _abService = NotificationABService();
  AnalyticsService _analytics = AnalyticsService();
  RichNotificationService _richNotificationService = RichNotificationService();
  NotificationStorageService _storageService = NotificationStorageService();

  /// Inject dependencies for testing
  @visibleForTesting
  void setDependencies({
    NotificationABService? abService,
    AnalyticsService? analytics,
    RichNotificationService? richNotificationService,
    NotificationStorageService? storageService,
  }) {
    if (abService != null) _abService = abService;
    if (analytics != null) _analytics = analytics;
    if (richNotificationService != null) _richNotificationService = richNotificationService;
    if (storageService != null) _storageService = storageService;
  }

  /// Sends a notification to the user.
  ///
  /// 1. Generates content using A/B testing service.
  /// 2. Tracks the 'send' event.
  /// 3. Stores the notification in Firestore.
  /// 4. Shows the local notification.
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    String? title, // Optional override
    String? body, // Optional override
    String? imageUrl,
    String? actionType,
    String? actionData,
    Map<String, dynamic>? params, // For dynamic content (e.g. names)
  }) async {
    try {
      // 1. Get A/B Group and Content
      final group = _abService.getGroup(userId);
      final content = _abService.getContent(userId, type, params: params);

      final finalTitle = title ?? content.title;
      final finalBody = body ?? content.body;

      // 2. Prepare Tracking Params
      final trackingParams = {
        'ab_group': group.toString().split('.').last, // 'control' or 'variant'
        'notification_type': type.toString().split('.').last,
        'user_id': userId,
        if (params != null) 'content_params': params,
      };

      // 3. Create Notification Model (Temporary ID)
      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: type.toString().split('.').last,
        title: finalTitle,
        message: finalBody,
        imageUrl: imageUrl,
        actionType: actionType,
        actionData: actionData,
        trackingParams: trackingParams,
        createdAt: DateTime.now(),
      );

      // 4. Track Send Event
      // We log BEFORE showing/saving to capture the attempt.
      await _analytics.logEvent('notification_sent', trackingParams);

      // 5. Store in Firestore (and get ID)
      final docId = await _storageService.saveNotification(notification);

      // Update model with the real ID for local notification
      final savedNotification = NotificationModel(
         id: docId,
         userId: notification.userId,
         type: notification.type,
         title: notification.title,
         message: notification.message,
         imageUrl: notification.imageUrl,
         actionType: notification.actionType,
         actionData: notification.actionData,
         trackingParams: notification.trackingParams,
         createdAt: notification.createdAt,
      );

      // 6. Show Local Notification
      await _richNotificationService.showNotification(savedNotification);

    } catch (e) {
      debugPrint('Error sending notification: $e');
      // Optionally log error to crash reporting
    }
  }
}

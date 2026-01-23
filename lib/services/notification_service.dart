import '../models/notification_model.dart';
import 'notification_ab_service.dart';
import 'notification_storage_service.dart';
import 'rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final NotificationABService _abService = NotificationABService();
  final NotificationStorageService _storageService = NotificationStorageService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  /// Sends a notification to a user.
  ///
  /// This method:
  /// 1. Determines the content using A/B testing.
  /// 2. Saves the notification to Firestore.
  /// 3. Logs the 'sent' event for tracking.
  /// 4. Shows the local notification.
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    Map<String, dynamic>? params,
    String? actionType,
    String? actionData,
    String? imageUrl,
  }) async {
    // 1. Get A/B Test Group and Content
    final group = _abService.getGroup(userId);
    final content = _abService.getContent(userId, type, params: params);

    // 2. Create Notification Model (Temporary ID)
    final tempNotification = NotificationModel(
      id: '',
      userId: userId,
      type: type.name, // Convert enum to string
      title: content.title,
      message: content.body,
      imageUrl: imageUrl,
      actionType: actionType,
      actionData: actionData,
      isRead: false,
      createdAt: DateTime.now(),
    );

    // 3. Save to Storage and get real ID
    final savedId = await _storageService.saveNotification(tempNotification);

    // Create final model with the real ID
    final finalNotification = NotificationModel(
      id: savedId,
      userId: userId,
      type: type.name,
      title: content.title,
      message: content.body,
      imageUrl: imageUrl,
      actionType: actionType,
      actionData: actionData,
      isRead: false,
      createdAt: tempNotification.createdAt,
    );

    // 4. Log 'sent' event
    await _abService.trackEvent(
      userId: userId,
      notificationId: savedId,
      type: type.name,
      group: group,
      event: 'sent',
    );

    // 5. Show Local Notification
    await _richNotificationService.showNotification(
      finalNotification,
      group: group,
    );
  }
}

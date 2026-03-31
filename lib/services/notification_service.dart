import 'package:flutter/foundation.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/notification_ab_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

/// Notification Service
///
/// Handles high-level notification logic including:
/// - Sending notifications (Local & Remote via Cloud Functions wrapper)
/// - A/B testing content generation
/// - Statistics tracking (Send/Click)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  final NotificationABService _abService = NotificationABService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  /// Track notification send event
  Future<void> trackNotificationSend(String type, String group) async {
    await _firestoreService.incrementNotificationStats(
      type: type,
      group: group,
      action: 'send',
    );
  }

  /// Track notification click event
  Future<void> trackNotificationClick(String type, String group) async {
    await _firestoreService.incrementNotificationStats(
      type: type,
      group: group,
      action: 'click',
    );
  }

  /// Send a local notification with tracking and A/B testing
  ///
  /// This is used for generating local notifications based on app events.
  /// For push notifications, the logic is typically on the server, but client-side
  /// tracking can still be useful if we can determine when a push is received.
  Future<void> sendLocalNotification({
    required UserModel recipient,
    required NotificationType type,
    String? actionType,
    String? actionData,
    String? imageUrl,
    Map<String, dynamic>? params,
  }) async {
    try {
      // 1. Determine A/B Group
      final group = _abService.getGroup(recipient.uid);
      final groupName = group == ExperimentGroup.control ? 'control' : 'variant';

      // 2. Generate Content
      final content = _abService.getContent(
        recipient.uid,
        type,
        params: params,
      );

      // 3. Create Notification Model
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate a unique ID
        title: content.title,
        message: content.body,
        type: type.name, // Convert enum to string
        timestamp: DateTime.now(),
        isRead: false,
        imageUrl: imageUrl,
        actionType: actionType,
        actionData: actionData,
        // Embed tracking info in payload via actionData or a separate field if model allows
        // Since NotificationModel might not have extra fields, we can append to actionData
        // or rely on the caller to know the context.
        // Ideally, we pass this metadata to RichNotificationService to persist in the payload.
      );

      // 4. Track Send
      // We track 'send' here (when we request to show it)
      await trackNotificationSend(type.name, groupName);

      // 5. Show Notification (Delegate to RichNotificationService)
      // We need to pass the group/type info to RichNotificationService so it can be
      // retrieved when clicked.
      // We'll verify if RichNotificationService supports custom payload data.
      // Looking at RichNotificationService, it encodes 'actionType' and 'actionData' into JSON payload.
      // We can encode the tracking info into 'actionData' if it's a string, or modify RichNotificationService.
      // For now, let's assume we can modify RichNotificationService to accept extra payload.
      // But to be safe with existing code, let's append tracking info to a specialized map if possible.
      // Or we can modify NotificationModel to include 'metadata'.

      // Let's modify RichNotificationService to accept 'trackingInfo' map.
      // But first, let's modify RichNotificationService.

      // For now, just call showNotification.
      // We will need to update RichNotificationService to handle tracking on click.
      await _richNotificationService.showNotification(
        notification,
        trackingInfo: {
          'type': type.name,
          'group': groupName,
        },
      );

    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'notification_ab_service.dart';
import 'rich_notification_service.dart';

/// Notification Service
///
/// Central service for sending notifications and tracking their statistics (sends/clicks)
/// specifically for A/B testing purposes.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationABService _abService = NotificationABService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  static const String _collectionName = 'notification_statistics';

  /// Sends a notification to a user, handling A/B content generation and stats tracking.
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    Map<String, dynamic>? params,
    String? actionData,
    String? actionType,
  }) async {
    try {
      // 1. Get A/B Content and Group
      final content = _abService.getContent(userId, type, params: params);
      final group = _abService.getGroup(userId);

      // 2. Generate Tracking ID
      final docRef = _firestore.collection(_collectionName).doc();
      final notificationId = docRef.id;

      // 3. Log "Send" Event
      await docRef.set({
        'userId': userId,
        'notificationId': notificationId,
        'type': type.toString().split('.').last, // e.g., 'match'
        'group': group.toString().split('.').last, // e.g., 'variant'
        'sentAt': FieldValue.serverTimestamp(),
        'isClicked': false,
        'clickedAt': null,
      });

      // 4. Create Notification Model
      // Map NotificationType to string expected by NotificationModel if necessary,
      // or use the type string directly. NotificationModel uses string types.
      final model = NotificationModel(
        id: notificationId,
        userId: userId,
        type: type.toString().split('.').last,
        title: content.title,
        message: content.body,
        actionType: actionType ?? _getDefaultActionType(type),
        actionData: actionData,
        createdAt: DateTime.now(),
      );

      // 5. Show Notification
      await _richNotificationService.showNotification(model);

    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Tracks a notification click event.
  ///
  /// This should be called when a user taps on a notification.
  Future<void> trackNotificationClick(String notificationId) async {
    if (notificationId.isEmpty) return;

    try {
      await _firestore.collection(_collectionName).doc(notificationId).update({
        'isClicked': true,
        'clickedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Notification click tracked: $notificationId');
    } catch (e) {
      debugPrint('Error tracking notification click: $e');
    }
  }

  /// Helper to determine default action type based on notification type
  String _getDefaultActionType(NotificationType type) {
    switch (type) {
      case NotificationType.match:
        return 'open_chat';
      case NotificationType.event:
        return 'view_event';
      case NotificationType.rating:
        return 'rate_experience'; // or similar
      case NotificationType.message:
        return 'open_chat';
      case NotificationType.system:
      default:
        return 'navigate';
    }
  }
}

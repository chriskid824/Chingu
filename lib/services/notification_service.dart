import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import 'notification_ab_service.dart';
import 'notification_storage_service.dart';
import 'rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final NotificationABService _abService = NotificationABService();
  final NotificationStorageService _storageService = NotificationStorageService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  /// Sends a notification to the user.
  ///
  /// This method:
  /// 1. Generates content using A/B testing service.
  /// 2. Saves the notification to storage.
  /// 3. Tracks the 'sent' event.
  /// 4. Displays the notification.
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    Map<String, dynamic>? params,
    String? actionType,
    String? actionData,
    String? imageUrl,
  }) async {
    try {
      // 1. Get content from A/B service
      final content = _abService.getContent(userId, type, params: params);

      // 2. Prepare NotificationModel
      // Generate ID using Firestore to ensure uniqueness and format consistency
      final String notificationId = FirebaseFirestore.instance.collection('notifications').doc().id;

      final notification = NotificationModel(
        id: notificationId,
        userId: userId,
        type: type.toString().split('.').last,
        title: content.title,
        message: content.body,
        imageUrl: imageUrl,
        actionType: actionType,
        actionData: actionData,
        createdAt: DateTime.now(),
        isRead: false,
      );

      // 3. Save to storage
      await _storageService.saveNotification(notification);

      // 4. Track 'sent' event
      await _abService.trackNotificationSent(userId, notificationId, type);

      // 5. Display notification
      await _richNotificationService.showNotification(notification);

    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Callback to be called when a notification is tapped.
  /// This should be hooked up to RichNotificationService.
  Future<void> onNotificationTap(String userId, String notificationId, String typeStr) async {
    NotificationType type;
    try {
      type = NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => NotificationType.system,
      );
    } catch (_) {
      type = NotificationType.system;
    }

    await _abService.trackNotificationClicked(userId, notificationId, type);
  }
}

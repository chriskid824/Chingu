import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import 'notification_ab_service.dart';
import 'notification_storage_service.dart';
import 'rich_notification_service.dart';
import 'analytics_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final NotificationABService _abService = NotificationABService();
  final NotificationStorageService _storageService = NotificationStorageService();
  final RichNotificationService _richService = RichNotificationService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initializes the service and sets up the click tracking callback.
  void initialize() {
    _richService.onTap = trackClick;
    debugPrint('[NotificationService] Initialized and wired to RichNotificationService');
  }

  /// Sends a notification to a user.
  ///
  /// 1. Determines content using A/B testing service.
  /// 2. Saves notification to Firestore.
  /// 3. Logs 'notification_sent' event with analytics.
  /// 4. If the recipient is the current user, shows a local notification.
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    Map<String, dynamic>? params,
    String? actionType,
    String? actionData,
    String? imageUrl,
  }) async {
    try {
      // 1. Get content from A/B Service
      final content = _abService.getContent(userId, type, params: params);
      final group = _abService.getGroup(userId);

      // 2. Create and Save Notification
      // NotificationStorageService.saveNotification returns the new document ID.
      final notificationData = NotificationModel(
        id: '', // Placeholder, ignored by add()
        userId: userId,
        type: type.name,
        title: content.title,
        message: content.body,
        imageUrl: imageUrl,
        actionType: actionType,
        actionData: actionData,
        createdAt: DateTime.now(),
      );

      final notificationId = await _storageService.saveNotification(notificationData);

      // 3. Log Analytics
      await _analyticsService.logEvent('notification_sent', {
        'notification_id': notificationId,
        'user_id': userId,
        'type': type.name,
        'group': group.name,
      });

      // 4. Show Local Notification if recipient is current user
      if (_auth.currentUser?.uid == userId) {
        // Create model with the actual ID for local notification
        final notificationWithId = NotificationModel(
          id: notificationId,
          userId: userId,
          type: type.name,
          title: content.title,
          message: content.body,
          imageUrl: imageUrl,
          actionType: actionType,
          actionData: actionData,
          createdAt: DateTime.now(),
        );

        await _richService.showNotification(notificationWithId);
      }
    } catch (e) {
      debugPrint('[NotificationService] Error sending notification: $e');
    }
  }

  /// Tracks a notification click.
  Future<void> trackClick(String id, String action, String? payload) async {
    try {
      await _analyticsService.logEvent('notification_clicked', {
        'notification_id': id,
        'action': action,
      });

      // Log the group if we can get current user ID
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
         final group = _abService.getGroup(currentUser.uid);
         await _analyticsService.logEvent('notification_clicked_enriched', {
           'notification_id': id,
           'group': group.name,
         });
      }
      debugPrint('[NotificationService] Tracked click for $id');
    } catch (e) {
      debugPrint('[NotificationService] Error tracking click: $e');
    }
  }
}

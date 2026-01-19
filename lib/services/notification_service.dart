import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import 'notification_ab_service.dart';
import 'rich_notification_service.dart';

/// Notification Service
///
/// Handles Firebase Messaging integration, A/B testing tracking,
/// and coordinates with RichNotificationService for display.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationABService _abService = NotificationABService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  Future<void> initialize() async {
    // Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      // Even if declined, we continue to listen (though we won't get much)
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Message opened app handler (Background -> App Open)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check initial message (Terminated -> App Open)
    try {
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      debugPrint('Error getting initial message: $e');
    }
  }

  /// Handles messages received while the app is in the foreground.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
        final data = message.data;
        // Check if we have enough data to construct a notification
        final String? userId = data['userId'] ?? FirebaseAuth.instance.currentUser?.uid;
        final String? type = data['notificationType'];

        if (userId != null && type != null) {
            // A/B Test Content Generation

            // Parse params from data
            Map<String, dynamic> params = Map<String, dynamic>.from(data);

            // Convert string type to enum if possible
            NotificationType? notificationType = _parseNotificationType(type);

            String title = message.notification?.title ?? '';
            String body = message.notification?.body ?? '';

            if (notificationType != null) {
                final content = _abService.getContent(userId, notificationType, params: params);
                title = content.title;
                body = content.body;

                // Track Send (Receipt/Display)
                await _abService.trackEvent(userId, type, 'sent');
            }

            final notification = NotificationModel(
                id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
                userId: userId,
                type: type,
                title: title,
                message: body,
                imageUrl: data['imageUrl'],
                actionType: data['actionType'],
                actionData: data['actionData'],
                createdAt: DateTime.now(),
            );

            await _richNotificationService.showNotification(notification);

        } else if (message.notification != null) {
            // Standard notification message without specific AB test type
             final notification = NotificationModel(
                id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
                userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                type: 'system',
                title: message.notification?.title ?? 'Notification',
                message: message.notification?.body ?? '',
                imageUrl: data['imageUrl'],
                actionType: data['actionType'],
                actionData: data['actionData'],
                createdAt: DateTime.now(),
            );
            await _richNotificationService.showNotification(notification);
        }
    } catch (e) {
        debugPrint('Error handling foreground message: $e');
    }
  }

  /// Handles messages that opened the app from background/terminated state.
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    try {
      final data = message.data;
      final String? userId = data['userId'] ?? FirebaseAuth.instance.currentUser?.uid;
      final String? type = data['notificationType'];

      if (userId != null && type != null) {
          await _abService.trackEvent(userId, type, 'click');
      }

      // Handle navigation
      // Extract action details
      final String? actionType = data['actionType'];
      final String? actionData = data['actionData'];

      // We pass null for actionId as this is a general notification tap, not a specific button
      _richNotificationService.handleNavigation(actionType, actionData, null);

    } catch (e) {
      debugPrint('Error handling opened app message: $e');
    }
  }

  NotificationType? _parseNotificationType(String type) {
    try {
      return NotificationType.values.firstWhere((e) => e.name == type);
    } catch (_) {
      return null;
    }
  }
}

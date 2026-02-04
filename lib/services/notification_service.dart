import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';
import 'rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });

    // Notification tap when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
    });

    _isInitialized = true;
  }

  /// Check for initial message (Cold start)
  Future<void> checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    // If there's no notification title/body, check data
    String title = message.notification?.title ?? message.data['title'] ?? '';
    String body = message.notification?.body ?? message.data['body'] ?? '';

    if (title.isEmpty && body.isEmpty) return;

    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().toString(),
      userId: '', // Not needed for local display
      type: message.data['type'] ?? 'system',
      title: title,
      message: body,
      imageUrl: message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );

    // Get Overlay State
    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedInAppNotification(
        notification: notification,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
        onTap: () {
          // Handle navigation
          RichNotificationService().handleNavigation(
            notification.actionType,
            notification.actionData,
            null, // actionId
          );
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }

  void _handleNotificationTap(RemoteMessage message) {
      final actionType = message.data['actionType'];
      final actionData = message.data['actionData'];

      RichNotificationService().handleNavigation(
        actionType,
        actionData,
        null
      );
  }
}

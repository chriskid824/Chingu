import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/routes/app_router.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access other Firebase services, they need to be initialized here.
  // Since we rely on the system to show the notification (for 'notification' payloads),
  // or onMessageOpenedApp for navigation, we might just log or do simple data processing here.
  debugPrint("Handling a background message: ${message.messageId}");
}

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

    // 1. Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      // 2. Set background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Handle terminated state (App opened from terminated state)
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageNavigation(initialMessage);
      }

      // 4. Handle background state (App opened from background state)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

      // 5. Handle foreground state
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
        }

        // Delegate to RichNotificationService to show local notification
        _showLocalNotification(message);
      });
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    _isInitialized = true;
  }

  void _handleMessageNavigation(RemoteMessage message) {
    debugPrint('Handling navigation for message: ${message.messageId}');
    final data = message.data;
    final String? actionType = data['actionType'];
    final String? actionData = data['actionData'];

    if (actionType != null) {
      final navigator = AppRouter.navigatorKey.currentState;
      if (navigator != null) {
        RichNotificationService().performAction(actionType, actionData, navigator);
      }
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    // Convert RemoteMessage to NotificationModel
    final notificationModel = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: message.data['userId'] ?? '',
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? message.data['title'] ?? '通知',
      message: message.notification?.body ?? message.data['message'] ?? '',
      imageUrl: message.data['imageUrl'] ??
                message.notification?.android?.imageUrl ??
                message.notification?.apple?.imageUrl,
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: message.sentTime ?? DateTime.now(),
    );

    RichNotificationService().showNotification(notificationModel);
  }
}

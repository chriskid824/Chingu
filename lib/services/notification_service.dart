import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';

/// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  // System handles display of notification payload automatically when in background
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Store data from the notification that launched the app (Terminated state)
  Map<String, dynamic>? pendingNotificationData;

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 2. Background Message Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');

      // Construct NotificationModel for display
      String title = message.notification?.title ?? message.data['title'] ?? '通知';
      String body = message.notification?.body ?? message.data['message'] ?? message.data['body'] ?? '';

      NotificationModel notification = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // Current user ID not strictly required for local display
        type: message.data['type'] ?? 'system',
        title: title,
        message: body,
        imageUrl: message.data['imageUrl'] ?? message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
        createdAt: DateTime.now(),
      );

      RichNotificationService().showNotification(notification);
    });

    // 4. Background Open Handler (App running in background -> Foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageInteraction(message.data);
    });

    // 5. Terminated Open Handler (App closed -> Opened)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state by notification');
      pendingNotificationData = initialMessage.data;
    }
  }

  /// Helper to trigger navigation via RichNotificationService
  void _handleMessageInteraction(Map<String, dynamic> data) {
    if (data.isNotEmpty) {
      final String? actionType = data['actionType'];
      final String? actionData = data['actionData'];
      // actionId is usually for buttons, here we just assume tap on body
      RichNotificationService().handleNavigation(actionType, actionData, null);
    }
  }
}

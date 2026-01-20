import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM Token
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
    }

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      _showLocalNotification(message);
    });

    // Background state (App opened from background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleRemoteNavigation(message);
    });
  }

  /// Check for initial message (Terminated state)
  Future<Map<String, String?>?> getInitialNotificationAction() async {
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      return _extractActionFromMessage(initialMessage);
    }
    return null;
  }

  void _showLocalNotification(RemoteMessage message) {
    final data = message.data;

    // Fallback values
    String title = message.notification?.title ?? data['title'] ?? 'New Notification';
    String body = message.notification?.body ?? data['message'] ?? data['body'] ?? '';

    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // Not used for display
      type: data['type'] ?? 'system',
      title: title,
      message: body,
      imageUrl: data['imageUrl'] ?? (message.notification?.android?.imageUrl),
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: DateTime.now(),
    );

    RichNotificationService().showNotification(notification);
  }

  void _handleRemoteNavigation(RemoteMessage message) {
     final actionMap = _extractActionFromMessage(message);
     if (actionMap != null) {
       RichNotificationService().handleNavigation(
         actionMap['actionType'],
         actionMap['actionData'],
         null,
       );
     }
  }

  Map<String, String?>? _extractActionFromMessage(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('actionType')) {
      return {
        'actionType': data['actionType'],
        'actionData': data['actionData'],
      };
    }
    // Also check if type implies action
    if (data['type'] == 'match') {
       return {
         'actionType': 'match_history',
         'actionData': null,
       };
    }

    return null;
  }
}

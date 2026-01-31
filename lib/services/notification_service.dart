import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/rich_notification_service.dart';

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
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Get FCM token
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint("FCM Token: $token");
      // Note: Token saving to Firestore should be handled here or in AuthProvider
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }

    // Handle background/terminated state tap
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleRemoteMessage(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleRemoteMessage(message);
    });

    // Handle foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });
  }

  void _handleRemoteMessage(RemoteMessage message) {
    debugPrint("Handling remote message: ${message.data}");
    final data = message.data;

    // Determine action type.
    // If 'actionType' is present, use it.
    // Otherwise map 'type' to action type if possible, or pass it directly.
    String? actionType = data['actionType'];
    if (actionType == null) {
        final type = data['type'];
        if (type == 'match') actionType = 'match';
        if (type == 'event') actionType = 'event';
        if (type == 'message') actionType = 'open_chat'; // Default message type to open_chat
    }

    final actionData = data['actionData'];

    // RichNotificationService handles the actual navigation
    RichNotificationService().handleNavigation(actionType, actionData, null);
  }

  void _showForegroundNotification(RemoteMessage message) {
    debugPrint("Showing foreground notification: ${message.notification?.title}");

    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().toString(),
      userId: '', // Not needed for display
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? message.data['title'] ?? '通知',
      message: message.notification?.body ?? message.data['message'] ?? '',
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl ?? message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );

    RichNotificationService().showNotification(notification);
  }
}

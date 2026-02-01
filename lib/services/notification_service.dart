import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';

// Background handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await RichNotificationService().initialize();

  debugPrint('Handling a background message: ${message.messageId}');

  // If it's a data-only message, we might want to show a notification locally.
  // If it has a notification payload, the system usually handles it.
  if (message.notification == null) {
    try {
      final data = message.data;
      final notification = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: data['userId'] ?? '',
        type: data['type'] ?? 'system',
        title: data['title'] ?? 'New Notification',
        message: data['message'] ?? 'You have a new message',
        imageUrl: data['imageUrl'],
        actionType: data['actionType'],
        actionData: data['actionData'],
        createdAt: DateTime.now(),
      );

      await RichNotificationService().showNotification(notification);
    } catch (e) {
      debugPrint('Error handling background message: $e');
    }
  }
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

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
    });

    // Background Message Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      _handleForegroundMessage(message);
    });

    _isInitialized = true;
  }

  Future<void> requestPermission() async {
    // Request permissions
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

    // Get FCM Token
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    try {
      // Prioritize notification payload if available, else use data
      String title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
      String body = message.notification?.body ?? message.data['message'] ?? '';

      final notification = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: message.data['userId'] ?? '',
        type: message.data['type'] ?? 'system',
        title: title,
        message: body,
        imageUrl: message.data['imageUrl'] ?? (message.notification?.android?.imageUrl),
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
        createdAt: message.sentTime ?? DateTime.now(),
      );

      RichNotificationService().showNotification(notification);
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }

  // Handle interactions (opening app from notification)
  Future<void> setupInteractedMessage() async {
    // 1. App opened from Terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      _handleMessageInteraction(initialMessage);
    }

    // 2. App opened from Background state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageInteraction);
  }

  void _handleMessageInteraction(RemoteMessage message) {
    debugPrint('Message interacted: ${message.messageId}');
    final data = message.data;

    final actionType = data['actionType'];
    final actionData = data['actionData'];

    if (actionType != null) {
      RichNotificationService().handleNavigation(actionType, actionData, null);
    }
  }
}

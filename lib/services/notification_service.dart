import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';

/// Top-level background handler must be outside any class
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here if needed.
  // FirebaseMessaging handles notification display automatically for 'notification' payload.
  // For 'data' only messages, we can perform background tasks here.
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

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      // Convert to NotificationModel and show
      final notification = _convertToNotificationModel(message);
      RichNotificationService().showNotification(notification);
    });

    // 4. Background Message Tapped Handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleRemoteMessageNavigation(message);
    });

    _isInitialized = true;
  }

  /// Checks for initial message (Terminated -> Open)
  Future<void> checkInitialMessage() async {
    try {
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();

      if (initialMessage != null) {
        debugPrint('App opened from terminated state by notification');
        _handleRemoteMessageNavigation(initialMessage);
      }
    } catch (e) {
      debugPrint('Error checking initial message: $e');
    }
  }

  void _handleRemoteMessageNavigation(RemoteMessage message) {
     final data = message.data;
     final actionType = data['actionType'] ?? data['type'];
     final actionData = data['actionData'] ?? data['senderId'] ?? data['eventId'];

     RichNotificationService().handleNavigation(
       actionType,
       actionData,
       null
     );
  }

  NotificationModel _convertToNotificationModel(RemoteMessage message) {
    // Priority: data > notification
    final data = message.data;
    final notification = message.notification;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // Not needed for display
      type: data['type'] ?? 'system',
      title: data['title'] ?? notification?.title ?? '',
      message: data['message'] ?? data['body'] ?? notification?.body ?? '',
      imageUrl: data['imageUrl'] ?? notification?.android?.imageUrl ?? notification?.apple?.imageUrl,
      actionType: data['actionType'] ?? data['type'],
      actionData: data['actionData'] ?? data['senderId'] ?? data['eventId'],
      createdAt: message.sentTime ?? DateTime.now(),
    );
  }
}

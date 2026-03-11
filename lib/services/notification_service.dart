import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
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

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      _showLocalNotification(message);
    });

    // Background/Terminated -> App Opened handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageNavigation(message);
    });

    _isInitialized = true;
  }

  /// Check if app was launched from a notification
  Future<void> checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from notification: ${initialMessage.messageId}');
      _handleMessageNavigation(initialMessage);
    }
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    String? actionType = data['actionType'];
    String? actionData = data['actionData'];

    RichNotificationService().handleNavigation(actionType, actionData, null);
  }

  void _showLocalNotification(RemoteMessage message) {
    String title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
    String body = message.notification?.body ?? message.data['message'] ?? message.data['body'] ?? '';

    if (title.isEmpty && body.isEmpty) return;

    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: message.data['userId'] ?? '',
      type: message.data['type'] ?? 'system',
      title: title,
      message: body,
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl ?? message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );

    RichNotificationService().showNotification(notification);
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

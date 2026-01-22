import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';

/// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
  // Note: Background messages are handled by the system tray mostly.
  // We can perform data updates here if needed.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final RichNotificationService _richNotificationService = RichNotificationService();

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

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Handle Terminated State (Cold Start)
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();

      if (initialMessage != null) {
        _handleRemoteMessage(initialMessage);
      }

      // 3. Handle Foreground State
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');

          // Convert RemoteMessage to NotificationModel
          // Note: RemoteMessage doesn't map 1:1 to our Firestore model, so we extract what we can
          final notification = NotificationModel(
            id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            userId: '', // Current user ID handling might be needed, but for display it's fine
            type: message.data['type'] ?? 'system',
            title: message.notification?.title ?? '',
            message: message.notification?.body ?? '',
            imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
            actionType: message.data['actionType'],
            actionData: message.data['actionData'],
            createdAt: DateTime.now(),
          );

          _richNotificationService.showNotification(notification);
        }
      });

      // 4. Handle Background State (App Opened from Notification)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        _handleRemoteMessage(message);
      });

      // Background message handler is registered in main.dart
    }
  }

  void _handleRemoteMessage(RemoteMessage message) {
     final String? actionType = message.data['actionType'];
     final String? actionData = message.data['actionData'];

     // Delegate navigation to RichNotificationService
     _richNotificationService.handleNotificationAction(actionType, actionData, null);
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;
}

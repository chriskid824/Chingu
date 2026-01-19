import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
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

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        // Create NotificationModel from RemoteMessage
        final notification = NotificationModel(
          id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: '', // Not really needed for display
          type: message.data['type'] ?? 'system',
          title: message.notification?.title ?? 'No Title',
          message: message.notification?.body ?? 'No Body',
          imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
          actionType: message.data['actionType'],
          actionData: message.data['actionData'],
          createdAt: DateTime.now(),
        );

        InAppNotification.show(
          notification: notification,
          onTap: () {
            debugPrint('Notification tapped: ${notification.title}');
            // Add navigation handling here if needed,
            // e.g. using RichNotificationService navigation logic or AppRouter
          },
        );
      }
    });

    _isInitialized = true;
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';

/// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access other Firebase services here, you must initialize Firebase.
  // await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  /// Initialize Notification Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
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

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle initial message (when app is terminated)
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      // Use a slight delay to allow the app to mount the navigator
      Future.delayed(const Duration(seconds: 1), () {
        _handleMessage(initialMessage);
      });
    }

    // Handle messages when app is in background but opened by user
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
       if (message.notification != null) {
          final notification = NotificationModel(
             id: message.messageId ?? DateTime.now().toString(),
             userId: '', // Not needed for local display
             type: 'remote',
             title: message.notification!.title ?? '',
             message: message.notification!.body ?? '',
             imageUrl: message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl,
             actionType: message.data['actionType'],
             actionData: message.data['actionData'],
             isRead: false,
             createdAt: DateTime.now(),
          );

          RichNotificationService().showNotification(notification);
       }
    });

    _isInitialized = true;
  }

  /// Handle navigation based on message
  void _handleMessage(RemoteMessage message) {
     final actionType = message.data['actionType'];
     final actionData = message.data['actionData'];

     final navigator = AppRouter.navigatorKey.currentState;
     if (navigator != null && actionType != null) {
        RichNotificationService().performAction(actionType, actionData, navigator);
     } else {
       debugPrint('Navigator is null or actionType is missing. Navigator: $navigator, Action: $actionType');
     }
  }
}

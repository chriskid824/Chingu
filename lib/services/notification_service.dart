import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp` before using other Firebase services.
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

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        // Show local notification
        // Construct NotificationModel from RemoteMessage
        final notification = NotificationModel(
          id: message.messageId ?? DateTime.now().toString(),
          userId: '', // Not strictly needed for local display
          type: message.data['type'] ?? 'system',
          title: message.notification?.title ?? 'Notification',
          message: message.notification?.body ?? '',
          imageUrl: message.data['imageUrl'],
          actionType: message.data['actionType'],
          actionData: message.data['actionData'],
          createdAt: DateTime.now(),
        );

        RichNotificationService().showNotification(notification);
      }
    });

    // Handle background state (app opened from background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessage(message);
    });

    // Handle terminated state (app opened from terminated)
    // We delay this check slightly to ensure the widget tree might be ready,
    // though the main safety comes from checking navigatorKey in RichNotificationService
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    // Wait for a frame to ensure things are more likely to be ready,
    // although `ChinguApp` initialization is early.
    // If we are in `initState`, `MaterialApp` is not built yet.
    // So we might need to wait until the app is fully mounted.
    // `WidgetsBinding.instance.addPostFrameCallback` might work if we have a context,
    // but here we are in a service.
    // We can just rely on `RichNotificationService` checking for `navigatorKey.currentState`.
    // If it is null, we might lose the navigation.
    // Ideally, we should store the initial message and handle it when the app is ready (e.g., in MainScreen).
    // However, for simplicity and meeting the requirement of "register in main.dart",
    // we will try to handle it.

    // A better approach for `getInitialMessage` is to call it, and if received,
    // wait until the router is ready.

    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('App opened from terminated state with message: ${initialMessage.messageId}');
      // We assume that by the time this async call returns, the app might be building.
      // But to be safe, we can add a slight delay or retry logic,
      // or we accept that if it's too fast, it might fail (and we log it).
      // Since `main` calls `runApp` after `initialize`, and `initialize` is async...
      // wait, `initialize` in `main` is awaited? No, in `initState` it is not awaited.

      // Let's retry a few times if navigator is null
      _retryHandleMessage(initialMessage);
    }
  }

  void _retryHandleMessage(RemoteMessage message, [int retries = 0]) {
     if (AppRouter.navigatorKey.currentState != null) {
       _handleMessage(message);
     } else {
       if (retries < 10) {
         Future.delayed(const Duration(milliseconds: 500), () {
           _retryHandleMessage(message, retries + 1);
         });
       } else {
         debugPrint('Failed to handle initial message: Navigator not ready');
       }
     }
  }

  void _handleMessage(RemoteMessage message) {
    // Extract actionType and actionData
    final actionType = message.data['actionType'];
    final actionData = message.data['actionData'];

    // Use RichNotificationService to handle navigation
    RichNotificationService().handleNavigation(actionType, actionData, null);
  }
}

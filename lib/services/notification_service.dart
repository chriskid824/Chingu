import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access other Firebase services here, you must initialize Firebase
  // await Firebase.initializeApp();
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

  /// Call this method from a StatefulWidget's initState (e.g. ChinguApp or MainScreen)
  /// to ensure Context/Navigator is available for navigation and UI interactions.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request permissions
    // Note: On iOS this might show a prompt. Ideally should be called when appropriate in UI flow,
    // but often done at startup.
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 3. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');

      if (message.notification != null) {
        // Show local notification via RichNotificationService
        final notification = NotificationModel(
          id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: '', // Foreground message might not have userId in payload easily, defaulting to empty or current user if available
          title: message.notification?.title ?? 'New Notification',
          message: message.notification?.body ?? '',
          type: message.data['type'] ?? 'system',
          timestamp: DateTime.now(),
          imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
          actionType: message.data['actionType'],
          actionData: message.data['actionData'],
          deeplink: message.data['deeplink'],
          createdAt: DateTime.now(),
        );

        RichNotificationService().showNotification(notification);
      }
    });

    // 4. Handle notification open (Background state -> Foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageInteraction(message);
    });

    // 5. Handle initial message (Terminated state -> Foreground)
    // We handle this here but ensure navigation happens after frame callback if called from initState
    _checkInitialMessage();

    _isInitialized = true;
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from terminated state via notification');
      // Wait a bit or use postFrameCallback if possible, but since we are in async method called from initState,
      // we might need to be careful.
      // Ideally, the caller of initialize() should handle timing, or we use explicit delay.
      // But _handleMessageInteraction uses NavigatorKey which works if MaterialApp is built.

      // If initialize() is called in initState of ChinguApp, MaterialApp might not be fully mounted yet for Navigator.
      // We should use WidgetsBinding.instance.addPostFrameCallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
         _handleMessageInteraction(initialMessage);
      });
    }
  }

  void _handleMessageInteraction(RemoteMessage message) {
      final actionType = message.data['actionType'];
      final actionData = message.data['actionData'];

      // Delegate navigation to RichNotificationService
      RichNotificationService().handleNavigation(actionType, actionData, null);
  }

  // Get token
  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }
}

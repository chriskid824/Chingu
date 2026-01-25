import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'rich_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
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
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 2. Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Handle background state (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    _isInitialized = true;
  }

  /// Check for initial message (App opened from terminated state)
  /// Should be called after UI is ready
  Future<void> checkForInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  void _handleMessage(RemoteMessage message) {
    // Pass the data to RichNotificationService for navigation
    // Firebase messages usually have data in 'data' map.
    // If the keys match what RichNotificationService expects (actionType, actionData, etc.)
    // it will work.
    if (message.data.isNotEmpty) {
      RichNotificationService().handleNavigation(message.data);
    }
  }
}

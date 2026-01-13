import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/routes/app_router.dart';
import '../firebase_options.dart';

/// Background message handler for Firebase Messaging.
/// This must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background handling
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

  /// Initialize Notification Service
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

    // 3. Check for Initial Message (Terminated state -> Opened)
    try {
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App launched from terminated state via notification');
        // Add a slight delay to ensure the navigator is ready if needed,
        // though strictly calling it here relies on the app being built.
        // Since initialize is called in main(), we might be too early for navigatorKey.currentState to be mounted.
        // We should handle this carefully.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleMessageNavigation(initialMessage);
        });
      }
    } catch (e) {
      debugPrint('Error getting initial message: $e');
    }

    // 4. Handle Notification Opened App (Background state -> Opened)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from background state via notification');
      _handleMessageNavigation(message);
    });

    _isInitialized = true;
  }

  /// Get FCM Token
  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Handle navigation based on notification payload
  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];

    // Use the global navigator key to navigate
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('Navigator state is null, cannot navigate');
      return;
    }

    debugPrint('Navigating based on actionType: $actionType');

    switch (actionType) {
      case 'open_chat':
      case 'message_new':
        // Navigate to Chat List
        navigator.pushNamed(AppRoutes.chatList);
        break;

      case 'view_event':
      case 'event_reminder':
      case 'event_change':
        // Navigate to Events List
        navigator.pushNamed(AppRoutes.eventsList);
        break;

      case 'match_history':
      case 'match_new':
      case 'match_success':
        // Navigate to Matches List
        navigator.pushNamed(AppRoutes.matchesList);
        break;

      default:
        // Default to Notifications Screen
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }
}

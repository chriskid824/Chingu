import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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
  RemoteMessage? _pendingInitialMessage;

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

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('Found initial message, storing as pending');
        _pendingInitialMessage = initialMessage;
      }

      // Handle background state (when app is opened from background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      _isInitialized = true;
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  /// Check and consume any pending initial message
  void consumePendingMessage() {
    if (_pendingInitialMessage != null) {
      debugPrint('Consuming pending initial message');
      _handleMessage(_pendingInitialMessage!);
      _pendingInitialMessage = null;
    }
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint('Handling message: ${message.messageId}');
    final data = message.data;
    // Check if keys exist in data, usually FCM data is flat map
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    _navigate(actionType, actionData);
  }

  void _navigate(String? actionType, String? actionData) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('Navigator key is null');
      return;
    }

    switch (actionType) {
      case 'open_chat':
        // Currently navigating to chat list as ChatDetail requires complex arguments (UserModel)
        // which need to be fetched asynchronously.
        navigator.pushNamed(AppRoutes.chatList);
        break;
      case 'view_event':
        // Pass actionData as argument (expected to be eventId)
        navigator.pushNamed(AppRoutes.eventDetail, arguments: actionData);
        break;
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList);
        break;
      default:
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }
}

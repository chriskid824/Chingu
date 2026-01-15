import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/routes/app_router.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  RemoteMessage? _pendingInitialMessage;

  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions (non-blocking)
    _requestPermission();

    // Check for initial message but don't handle it yet (Navigator not ready)
    _pendingInitialMessage = await _messaging.getInitialMessage();

    // Handle background state (app opened from background state)
    // This is safe to listen to, but the callback will only fire when user taps.
    // By then Navigator should be ready if app is in foreground.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((fcmToken) {
      debugPrint("FCM Token refreshed: $fcmToken");
    }).onError((err) {
      debugPrint("Error getting token: $err");
    });
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  /// Call this method from the main widget (e.g. MainScreen) after the app is mounted
  void processInitialMessage() {
    if (_pendingInitialMessage != null) {
      debugPrint("Processing pending initial message");
      _handleMessage(_pendingInitialMessage!);
      _pendingInitialMessage = null;
    }
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint('Handling message open: ${message.data}');

    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    _performNavigation(actionType, actionData);
  }

  void _performNavigation(String? actionType, String? actionData) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('Navigator state is null - Cannot navigate');
      return;
    }

    switch (actionType) {
      case 'open_chat':
        navigator.pushNamed(AppRoutes.chatList, arguments: actionData);
        break;
      case 'view_event':
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

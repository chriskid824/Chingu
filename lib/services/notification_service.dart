import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/core/routes/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  Future<void> initialize() async {
    // 1. Register background handler immediately
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Setup message listeners
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 3. Setup token listeners
    _setupTokenListeners();

    // 4. Handle initial message (async)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? initialMessage) {
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    });

    // 5. Request permission and get token (async, don't block initialization if not awaited)
    _requestPermissionAndToken();
  }

  void _setupTokenListeners() {
    // Listen to refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveToken);

    // Listen to auth state
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _firebaseMessaging.getToken().then((token) {
          if (token != null) {
            _saveToken(token);
          }
        });
      }
    });
  }

  Future<void> _requestPermissionAndToken() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      try {
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          _saveToken(token);
        }
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {'fcmToken': token});
        debugPrint('FCM Token saved: $token');
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');

      final notification = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        type: message.data['type'] ?? 'system',
        title: message.notification?.title ?? 'No Title',
        message: message.notification?.body ?? 'No Body',
        imageUrl: message.notification?.android?.imageUrl ?? message.data['imageUrl'],
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
        createdAt: DateTime.now(),
      );

      _richNotificationService.showNotification(notification);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');

    final String? actionType = message.data['actionType'];
    final String? actionData = message.data['actionData'];
    final navigator = AppRouter.navigatorKey.currentState;

    if (navigator != null && actionType != null) {
      debugPrint('Handling action: $actionType with data: $actionData');
      switch (actionType) {
        case 'open_chat':
          navigator.pushNamed(AppRoutes.chatList);
          break;
        case 'view_event':
          navigator.pushNamed(AppRoutes.eventDetail);
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
}

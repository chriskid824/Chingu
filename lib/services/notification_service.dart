import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';
import '../firebase_options.dart';
import '../core/routes/app_router.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint("Handling a background message: ${message.messageId}");

  // Note: We don't usually show UI in background handler unless it's a data-only message
  // that needs a local notification. If the payload contains 'notification',
  // the system tray handles it automatically.

  // Initialize RichNotificationService to be safe if we need to show local notification
  // for data messages.
  await RichNotificationService().initialize();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isInitialized = false;
  RemoteMessage? _pendingInitialMessage;

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

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Setup Message Handlers

      // Foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');

          // Show local notification using RichNotificationService
          final notification = NotificationModel(
            id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: message.notification?.title ?? '新通知',
            message: message.notification?.body ?? '',
            timestamp: DateTime.now(),
            isRead: false,
            type: message.data['type'] ?? 'general',
            imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
            actionType: message.data['actionType'],
            actionData: message.data['actionData'],
          );

          RichNotificationService().showNotification(notification);
        }
      });

      // Background State (App Open)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        _handleMessageNavigation(message);
      });

      // Terminated State (App Launch)
      // We store the message here and handle it when the UI is ready
      _pendingInitialMessage = await _firebaseMessaging.getInitialMessage();
      if (_pendingInitialMessage != null) {
        debugPrint('App launched from terminated state via notification');
      }

      // 3. Token Management
      await _setupToken();
    }

    _isInitialized = true;
  }

  Future<void> _setupToken() async {
    try {
      // Get the token each time the application loads
      String? token = await _firebaseMessaging.getToken();
      debugPrint("FCM Token: $token");

      // Save to Firestore if user is logged in
      await _saveTokenToDatabase(token);

      // Any time the token refreshes, store it in the database.
      _firebaseMessaging.onTokenRefresh.listen((String newToken) async {
         debugPrint("FCM Token Refreshed: $newToken");
         await _saveTokenToDatabase(newToken);
      });

      // Listen for auth changes to save token when user logs in
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          String? currentToken = await _firebaseMessaging.getToken();
          if (currentToken != null) {
            await _saveTokenToDatabase(currentToken);
          }
        }
      });
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }
  }

  Future<void> _saveTokenToDatabase(String? token) async {
    if (token == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestoreService.updateFcmToken(user.uid, token);
      debugPrint("FCM Token saved to Firestore for user: ${user.uid}");
    }
  }

  /// Handle any pending initial message (Terminated state)
  /// Call this when the App is mounted and Navigator is ready
  void handlePendingInitialMessage() {
    if (_pendingInitialMessage != null) {
      _handleMessageNavigation(_pendingInitialMessage!);
      _pendingInitialMessage = null;
    }
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    if (actionType != null) {
      switch (actionType) {
        case 'open_chat':
          // Navigate to chat list or specific chat if actionData has chatRoomId
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

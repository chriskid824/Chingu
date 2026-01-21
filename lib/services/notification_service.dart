import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access other Firebase services here, you might need to initialize Firebase
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
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

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      // Even if permission is denied, we continue setup, but notifications won't show.
    }

    // 2. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      _handleForegroundMessage(message);
    });

    // 4. Handle Notification Opened App (Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageOpenedApp(message);
    });

    // 5. Handle Initial Message (Terminated)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from terminated state via notification');
      _handleMessageOpenedApp(initialMessage);
    }

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
       // Since we don't know the userId here easily without Auth,
       // typically we handle this where Auth is available or just let the next app start update it.
       // However, if we want to support logout/login token updates, we usually handle it in AuthProvider.
       debugPrint("FCM Token refreshed: $newToken");
    });
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Update FCM token in Firestore for the given user
  Future<void> updateFCMToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint("FCM Token updated for user $userId");
      }
    } catch (e) {
      debugPrint("Error updating FCM token: $e");
    }
  }

  /// Handle incoming foreground message by showing a local notification
  void _handleForegroundMessage(RemoteMessage message) {
    // Convert RemoteMessage to NotificationModel
    final notificationModel = _convertRemoteMessageToModel(message);

    // Show using RichNotificationService
    RichNotificationService().showNotification(notificationModel);
  }

  /// Handle message that opened the app
  void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    // Use AppRouter's navigatorKey to navigate
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator != null) {
       _performNavigation(actionType, actionData, navigator);
    }
  }

  void _performNavigation(String? actionType, String? actionData, NavigatorState navigator) {
    debugPrint("Performing navigation: type=$actionType, data=$actionData");

    switch (actionType) {
      case 'open_chat':
        if (actionData != null) {
           // actionData should be chatRoomId.
           // However, ChatDetailScreen might require arguments.
           // Based on memory, RichNotificationService uses pushNamed(AppRoutes.chatList) temporarily.
           // But if ChatDetailScreen supports deep linking via chatRoomId, we should try that if the router supports it.
           // Currently AppRoutes.chatDetail usually expects arguments.
           // For now, consistent with RichNotificationService:
           navigator.pushNamed(AppRoutes.chatList);
        } else {
           navigator.pushNamed(AppRoutes.chatList);
        }
        break;
      case 'view_event':
        // Same as RichNotificationService
        navigator.pushNamed(AppRoutes.eventDetail);
        break;
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList);
        break;
      default:
        // Default to notifications screen
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }

  NotificationModel _convertRemoteMessageToModel(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // Not needed for local display
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? 'Notification',
      message: notification?.body ?? data['message'] ?? '',
      imageUrl: notification?.android?.imageUrl ?? data['imageUrl'],
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: message.sentTime ?? DateTime.now(),
      isRead: false,
    );
  }
}

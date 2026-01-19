import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/rich_notification_service.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';

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

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
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
      return;
    }

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      _handleForegroundMessage(message);
    });

    // Message opened app from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleNavigation(message);
    });

    // Check initial message (from terminated state)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
       _handleNavigation(initialMessage);
    }

    // Listen to token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  Future<void> updateFCMToken() async {
    String? token = await getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token updated for user: ${user.uid}');
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
     final data = message.data;
     final notification = message.notification;

     if (notification != null || (data.containsKey('title') && data.containsKey('message'))) {

        final title = notification?.title ?? data['title'] ?? 'New Notification';
        final body = notification?.body ?? data['message'] ?? '';

        final id = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

        final model = NotificationModel(
            id: id,
            userId: FirebaseAuth.instance.currentUser?.uid ?? '',
            type: data['type'] ?? 'system',
            title: title,
            message: body,
            imageUrl: data['imageUrl'],
            actionType: data['actionType'],
            actionData: data['actionData'],
            createdAt: DateTime.now(),
        );

        RichNotificationService().showNotification(model);
     }
  }

  void _handleNavigation(RemoteMessage message) {
      final data = message.data;
      final actionType = data['actionType'];
      // final actionData = data['actionData']; // Not used currently but available

      final navigator = AppRouter.navigatorKey.currentState;
      if (navigator == null) return;

      if (actionType != null) {
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
      } else {
         navigator.pushNamed(AppRoutes.notifications);
      }
  }
}

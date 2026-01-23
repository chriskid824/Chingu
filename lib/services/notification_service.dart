import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';
import '../core/routes/app_router.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Get and Save Token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // 3. Listen to Token Refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // 4. Foreground Message Handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showForegroundNotification(message);
      }
    });

    // 5. Setup Background -> Foreground listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  Future<void> _saveTokenToFirestore(String token) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token saved to Firestore');
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final notificationModel = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: message.data['type'] ?? 'system',
        title: notification.title ?? '',
        message: notification.body ?? '',
        imageUrl: android?.imageUrl ?? message.data['imageUrl'],
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
        createdAt: DateTime.now(),
      );

      RichNotificationService().showNotification(notificationModel);
    }
  }

  /// Check for initial message when app opens from terminated state.
  /// Should be called when Navigator is ready.
  Future<void> checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint('Handling interacted message: ${message.data}');

    // Extract action info
    final String? actionType = message.data['actionType'];
    // final String? actionData = message.data['actionData']; // Available if needed

    if (actionType != null) {
        final navigator = AppRouter.navigatorKey.currentState;
        if (navigator != null) {
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
             }
        }
    }
  }
}

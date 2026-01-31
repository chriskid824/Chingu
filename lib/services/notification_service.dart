import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

// Top-level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access other Firebase services, initialize them here
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
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> initialize() async {
    // 1. Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
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

    // 2. Background Message Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // Show local notification
        _showLocalNotification(message);
      }
    });

    // 4. Handle Interacted Messages (Background -> Foreground / Terminated -> Foreground)
    // Removed from initialize() to be called from UI when navigator is ready.

    // 5. Get and Save Token
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from a terminated state.
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    // Delegate navigation to RichNotificationService
    RichNotificationService().handleNavigation(actionType, actionData, null);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
     final notification = message.notification;
     final data = message.data;

     if (notification == null) return;

     // Construct NotificationModel
     final model = NotificationModel(
       id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
       userId: FirebaseAuth.instance.currentUser?.uid ?? '', // Best effort
       type: data['type'] ?? 'system',
       title: notification.title ?? '',
       message: notification.body ?? '',
       imageUrl: data['imageUrl'],
       actionType: data['actionType'],
       actionData: data['actionData'],
       createdAt: DateTime.now(),
     );

     await RichNotificationService().showNotification(model);
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
       await _firestoreService.updateUser(user.uid, {'fcmToken': token});
    }
  }
}

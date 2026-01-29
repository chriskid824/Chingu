import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
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
    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
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

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      _showForegroundNotification(message);
    });

    // Handle notification open (background/terminated handled by system or getInitialMessage)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        // Note: Navigation is typically handled by the routing system or specific
        // logic that parses the message data. Since RichNotificationService handles
        // local notification taps, we might rely on that for foreground.
        // For background taps, the system opens the app.
        // Deep linking logic would go here if not handled by getInitialMessage
    });
  }

  Future<void> updateFCMToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(userId, token);
      }

      _firebaseMessaging.onTokenRefresh.listen((token) {
          _saveTokenToFirestore(userId, token);
      });
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM Token updated for user $userId');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    // Convert RemoteMessage to NotificationModel
    // We try to extract data from both 'notification' and 'data' fields

    final String title = message.notification?.title ?? message.data['title'] ?? '新通知';
    final String body = message.notification?.body ?? message.data['message'] ?? message.data['body'] ?? '';

    // If there is no title and body, we might skip showing it, or show default
    if (title.isEmpty && body.isEmpty) return;

    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final notificationModel = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: message.data['type'] ?? 'system',
      title: title,
      message: body,
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl ?? message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      isRead: false,
      createdAt: message.sentTime ?? DateTime.now(),
    );

    RichNotificationService().showNotification(notificationModel);
  }
}

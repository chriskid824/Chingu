import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'rich_notification_service.dart';
import 'notification_ab_service.dart';
import '../models/notification_model.dart';

// Background handler must be top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access other Firebase services, initialize them.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationABService _abService = NotificationABService();

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    // Get initial token if user is already logged in or just get it ready
    await checkAndSaveToken();

    // Listen to token refresh
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
       debugPrint('Got a message whilst in the foreground!');
       debugPrint('Message data: ${message.data}');

       _handleForegroundMessage(message);
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
      String? title = message.notification?.title;
      String? body = message.notification?.body;
      String? imageUrl = message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl;

      final data = message.data;
      final typeString = data['type'] ?? 'system';

      // If notification payload is missing, try to generate content via AB Service
      if (title == null || body == null) {
          final userId = _auth.currentUser?.uid;
          if (userId != null) {
              NotificationType type;
              switch(typeString) {
                  case 'match': type = NotificationType.match; break;
                  case 'message': type = NotificationType.message; break;
                  case 'event': type = NotificationType.event; break;
                  case 'rating': type = NotificationType.rating; break;
                  default: type = NotificationType.system;
              }

              final content = _abService.getContent(userId, type, params: data);
              title = title ?? content.title;
              body = body ?? content.body;
          } else {
             title = title ?? 'Notification';
             body = body ?? 'You have a new notification';
          }
      }

      final notification = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _auth.currentUser?.uid ?? '',
        type: typeString,
        title: title!,
        message: body!,
        imageUrl: imageUrl ?? data['imageUrl'],
        actionType: data['actionType'],
        actionData: data['actionData'],
        createdAt: DateTime.now(),
      );

      // Use RichNotificationService to display
      await RichNotificationService().showNotification(notification);
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token saved to Firestore');
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    }
  }

  Future<void> checkAndSaveToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }
}

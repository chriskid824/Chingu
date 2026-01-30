import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';
import '../core/routes/app_router.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
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
      return;
    }

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        // Show local notification
        _showLocalNotification(message);
      }
    });

    // Message opened app handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessage(message);
    });

    // Check if app was opened from a terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Token refresh handler
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      _saveTokenToFirestore(token);
    });

    // Get and save initial token if user is logged in
    _checkAndSaveToken();

    // Listen to auth state changes to save token when user logs in
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _checkAndSaveToken();
      }
    });
  }

  Future<void> _checkAndSaveToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token saved to Firestore for user ${user.uid}');
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
       // Construct NotificationModel
       final model = NotificationModel(
         id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
         userId: _auth.currentUser?.uid ?? '',
         type: message.data['type'] ?? 'system',
         title: notification.title ?? '',
         message: notification.body ?? '',
         imageUrl: android?.imageUrl ?? message.data['image'],
         actionType: message.data['actionType'],
         actionData: message.data['actionData'],
         createdAt: DateTime.now(),
       );

       RichNotificationService().showNotification(model);
    }
  }

  void _handleMessage(RemoteMessage message) {
    // Extract action type and data
    final String? actionType = message.data['actionType'];
    // final String? actionData = message.data['actionData']; // Used in specific routes if needed

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
       // Default fallback
       navigator.pushNamed(AppRoutes.notifications);
    }
  }
}

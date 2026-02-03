import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // 1. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        final notification = NotificationModel(
             id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
             userId: _auth.currentUser?.uid ?? '',
             type: message.data['type'] ?? 'system',
             title: message.notification?.title ?? '通知',
             message: message.notification?.body ?? '',
             imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
             actionType: message.data['actionType'],
             actionData: message.data['actionData'],
             isRead: false,
             createdAt: DateTime.now(),
        );

        RichNotificationService().showNotification(notification);
      }
    });

    // 2. Handle Background/Terminated Messages (onMessageOpenedApp)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
       debugPrint('A new onMessageOpenedApp event was published!');
       _handleMessageNavigation(message);
    });

    // 3. Handle Terminated State (getInitialMessage)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated state by notification: ${message.messageId}');
        _handleMessageNavigation(message);
      }
    });

    // 4. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Update Token on startup and refresh
    await _updateToken();
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken);
    });

    // 6. Listen to auth state changes to save token when user logs in
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _updateToken();
      }
    });

    // 7. Request Permission (Last to avoid blocking listeners)
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
  }

  Future<void> _updateToken() async {
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
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('FCM Token saved to Firestore for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  void _handleMessageNavigation(RemoteMessage message) {
     final actionType = message.data['actionType'];
     final actionData = message.data['actionData'];
     RichNotificationService().handleNavigation(actionType, actionData, null);
  }
}

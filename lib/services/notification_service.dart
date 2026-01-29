import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'firestore_service.dart';
import 'rich_notification_service.dart';

// Background handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _tokenRefreshSubscription;
  StreamSubscription? _authStateSubscription;

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
      // Even if declined, we continue initialization to handle potential changes or other logic
    }

    // 2. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        final notification = NotificationModel(
             id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
             userId: _auth.currentUser?.uid ?? '',
             type: message.data['type'] ?? 'system',
             title: message.notification?.title ?? '',
             message: message.notification?.body ?? '',
             imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
             actionType: message.data['actionType'],
             actionData: message.data['actionData'],
             createdAt: DateTime.now(),
        );

        RichNotificationService().showNotification(notification);
      }
    });

    // 4. Handle Notification Tap (Opened App)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        final actionType = message.data['actionType'];
        final actionData = message.data['actionData'];

        if (actionType != null) {
          RichNotificationService().performAction(actionType, actionData);
        }
    });

    // 5. Check Initial Message (App opened from terminated state)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
         debugPrint('App opened from terminated state via notification');
         final actionType = initialMessage.data['actionType'];
         final actionData = initialMessage.data['actionData'];

         if (actionType != null) {
             // Delay slightly to ensure navigation is ready
             Future.delayed(const Duration(milliseconds: 500), () {
                 RichNotificationService().performAction(actionType, actionData);
             });
         }
    }

    // 6. Token Management
    await _checkAndSaveToken();
    _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });

    // 7. Auth State Listener
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
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
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token updated for user ${user.uid}');
      } catch (e) {
        debugPrint('Error updating FCM token in Firestore: $e');
      }
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _authStateSubscription?.cancel();
  }
}

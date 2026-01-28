import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  FirebaseMessaging? _messagingInstance;
  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;

  FirebaseMessaging get _messaging => _messagingInstance ??= FirebaseMessaging.instance;
  FirebaseFirestore get _firestore => _firestoreInstance ??= FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;

  // For testing
  @visibleForTesting
  set messaging(FirebaseMessaging messaging) => _messagingInstance = messaging;
  @visibleForTesting
  set firestore(FirebaseFirestore firestore) => _firestoreInstance = firestore;
  @visibleForTesting
  set auth(FirebaseAuth auth) => _authInstance = auth;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
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
      // Even if declined, we continue setup so if they enable it later, it works?
      // We still listen to messages in case they are sent (e.g. data messages might still arrive on Android?)
      // Actually data messages are not affected by notification permission on Android.
    }

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get token
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // Listen to token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // Foreground message
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Message opened app (Background -> Foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Check initial message (Terminated -> Foreground)
    try {
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _onInitialMessage(initialMessage);
      }
    } catch (e) {
      debugPrint('Error getting initial message: $e');
    }

    // Listen to auth state changes to update token when user logs in
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _messaging.getToken().then((token) {
          if (token != null) {
            _saveTokenToFirestore(token);
          }
        });
      }
    });
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      // It's a notification message
      final model = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _auth.currentUser?.uid ?? '',
        type: message.data['type'] ?? 'system',
        title: notification.title ?? '',
        message: notification.body ?? '',
        imageUrl: android?.imageUrl ?? message.data['imageUrl'],
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
        createdAt: DateTime.now(),
      );

      await RichNotificationService().showNotification(model);
    } else {
      // Data only message
       if (message.data.containsKey('title') && message.data.containsKey('body')) {
          final model = NotificationModel(
            id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            userId: _auth.currentUser?.uid ?? '',
            type: message.data['type'] ?? 'system',
            title: message.data['title'],
            message: message.data['body'],
            imageUrl: message.data['imageUrl'],
            actionType: message.data['actionType'],
            actionData: message.data['actionData'],
            createdAt: DateTime.now(),
          );
          await RichNotificationService().showNotification(model);
       }
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');
    _handleMessageNavigation(message);
  }

  void _onInitialMessage(RemoteMessage message) {
    debugPrint('Initial message: ${message.messageId}');
    _handleMessageNavigation(message);
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final String? actionType = message.data['actionType'];
    final String? actionData = message.data['actionData'];

    if (actionType != null) {
      RichNotificationService().performAction(actionType, actionData);
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token saved to Firestore for user: ${user.uid}');
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    } else {
      debugPrint('User not logged in, skipping token save');
    }
  }

  /// 手動保存 Token (可供外部調用，例如 LoginScreen)
  Future<void> saveToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Error manually saving token: $e');
    }
  }
}

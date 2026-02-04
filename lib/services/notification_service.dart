import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

/// Top-level background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access Firestore here, you must call Firebase.initializeApp()
  await Firebase.initializeApp();
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
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      // 2. Set up background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Handle token
      await _setupToken();

      // 4. Handle incoming messages
      _setupMessageHandlers();

      _isInitialized = true;
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  Future<void> _setupToken() async {
    // Get initial token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _saveTokenToFirestore(token);
    });

    // Listen to auth changes to save token when user logs in
    _firebaseAuth.authStateChanges().listen((User? user) async {
      if (user != null) {
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
        }
      }
    });
  }

  Future<void> _saveTokenToFirestore(String token) async {
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {'fcmToken': token});
        debugPrint('FCM Token updated for user: ${user.uid}');
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }
    }
  }

  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        // Show rich notification
        final notification = NotificationModel(
          id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: _firebaseAuth.currentUser?.uid ?? '',
          type: message.data['type'] ?? 'system',
          title: message.notification!.title ?? 'New Notification',
          message: message.notification!.body ?? '',
          imageUrl: message.notification!.android?.imageUrl ?? message.data['imageUrl'],
          actionType: message.data['actionType'],
          actionData: message.data['actionData'],
          createdAt: DateTime.now(),
        );

        RichNotificationService().showNotification(notification);
      }
    });

    // Background/Terminated -> Opened App
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageInteraction(message);
    });

    // Check if app was opened from a terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated state by notification');
        _handleMessageInteraction(message);
      }
    });
  }

  void _handleMessageInteraction(RemoteMessage message) {
    final actionType = message.data['actionType'];
    final actionData = message.data['actionData'];

    if (actionType != null) {
      RichNotificationService().handleNavigation(actionType, actionData, null);
    }
  }
}

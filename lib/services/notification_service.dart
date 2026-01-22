import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RichNotificationService _richNotificationService = RichNotificationService();

  Future<void> initialize() async {
    // 1. Request Permission
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

    // 2. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showForegroundNotification(message);
      } else {
        // Handle data-only messages if necessary
        if (message.data.containsKey('title') ||
            message.data.containsKey('body') ||
            message.data.containsKey('message')) {
            _showForegroundNotification(message);
        }
      }
    });

    // 4. Handle Token
    // Get current token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen((String newToken) {
      _saveTokenToFirestore(newToken);
    });

    // Listen to auth state changes to save token when user logs in
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _firebaseMessaging.getToken().then((token) {
          if (token != null) {
            _saveTokenToFirestore(token);
          }
        });
      }
    });

    // 5. Initial Message (Open from Terminated)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageInteraction(initialMessage);
    }

    // 6. Open App from Background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageInteraction);
  }

  Future<void> _saveTokenToFirestore(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token saved to Firestore: $token');
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
        // Optionally handle document not found case, though unlikely for logged in user
      }
    } else {
      debugPrint('User not logged in, skipping token save');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    String title = notification?.title ?? data['title'] ?? 'New Notification';
    String body = notification?.body ?? data['message'] ?? data['body'] ?? '';
    String? imageUrl = notification?.android?.imageUrl ?? notification?.apple?.imageUrl ?? data['imageUrl'];
    String? actionType = data['actionType'];
    String? actionData = data['actionData'];
    String type = data['type'] ?? 'system';

    // Avoid showing empty notifications
    if (title.isEmpty && body.isEmpty) return;

    final model = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _auth.currentUser?.uid ?? '',
      type: type,
      title: title,
      message: body,
      imageUrl: imageUrl,
      actionType: actionType,
      actionData: actionData,
      createdAt: DateTime.now(),
      isRead: false,
    );

    _richNotificationService.showNotification(model);
  }

  void _handleMessageInteraction(RemoteMessage message) {
    final data = message.data;
    final String? actionType = data['actionType'];
    final String? actionData = data['actionData'];

    _richNotificationService.handleNotificationAction(actionType, actionData, null);
  }
}

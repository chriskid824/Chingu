import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';
import '../firebase_options.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
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

    // Get Initial Message (Terminated state)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageNavigation(initialMessage);
    }

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Listen to background/terminated message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

    _isInitialized = true;
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> _saveTokenToFirestore(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
        debugPrint('FCM Token updated for user ${user.uid}');
      } catch (e) {
        debugPrint('Error updating FCM Token: $e');
      }
    }
  }

  /// Public method to check and save token (e.g., after login)
  Future<void> checkAndSaveToken() async {
    try {
      String? token = await getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    try {
      final model = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _auth.currentUser?.uid ?? '',
        type: data['type'] ?? 'system',
        title: notification.title ?? '',
        message: notification.body ?? '',
        imageUrl: data['imageUrl'] ?? notification.android?.imageUrl ?? notification.apple?.imageUrl,
        actionType: data['actionType'],
        actionData: data['actionData'],
        createdAt: DateTime.now(),
      );

      RichNotificationService().showNotification(model);
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    // Pass null for actionId as this is a general notification tap, not a button tap
    RichNotificationService().handleNavigation(actionType, actionData, null);
  }
}

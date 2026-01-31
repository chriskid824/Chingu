import 'package:chingu/firebase_options.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

    // Request permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen to onMessageOpenedApp (Background -> Open)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Listen to onMessage (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );

        final notification = NotificationModel(
          id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: _auth.currentUser?.uid ?? '',
          type: message.data['type'] ?? 'system',
          title: message.notification?.title ?? '',
          message: message.notification?.body ?? '',
          imageUrl: message.notification?.android?.imageUrl ??
              message.notification?.apple?.imageUrl,
          actionType: message.data['actionType'],
          actionData: message.data['actionData'],
          createdAt: DateTime.now(),
        );

        RichNotificationService().showNotification(notification);
      }
    });

    // Token management
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // Check and save initial token
    final String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // Listen to Auth state changes to update token
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        final String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _saveTokenToDatabase(token);
        }
      }
    });

    _isInitialized = true;
  }

  Future<void> checkInitialMessage() async {
    // Check for initial message (Terminated -> Open)
    final RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token updated for user: ${user.uid}');
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }
    }
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint('Handling message open: ${message.messageId}');
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    // Use RichNotificationService to handle navigation
    RichNotificationService().handleNavigation(actionType, actionData, null);
  }
}

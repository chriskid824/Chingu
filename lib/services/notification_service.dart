import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request permission
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

    // 2. Get Initial Token
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }

    // 3. Monitor token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint("FCM Token refreshed: $newToken");
      _saveTokenToFirestore(newToken);
    });

    // 4. Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showForegroundNotification(message);
      }
    });

    // 5. Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 6. Auth State Changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _firebaseMessaging.getToken().then((token) {
          if (token != null) {
            _saveTokenToFirestore(token);
          }
        });
      }
    });

    _isInitialized = true;
  }

  Future<void> _saveTokenToFirestore(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("FCM Token saved to Firestore for user ${user.uid}");
      } catch (e) {
        debugPrint("Error updating token in Firestore: $e");
      }
    } else {
      debugPrint("User not logged in, skipping token save");
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      final Map<String, dynamic> data = message.data;
      final String type = data['type'] ?? 'system';
      final String? actionType = data['actionType'];
      final String? actionData = data['actionData'];

      final notificationModel = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _auth.currentUser?.uid ?? '',
        type: type,
        title: notification.title ?? '',
        message: notification.body ?? '',
        imageUrl: android?.imageUrl ?? (data['imageUrl'] as String?),
        actionType: actionType,
        actionData: actionData,
        createdAt: DateTime.now(),
        isRead: false,
      );

      RichNotificationService().showNotification(notificationModel);
    }
  }
}

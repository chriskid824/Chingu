import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access other Firebase services in the background,
  // you might need to initialize Firebase.
  // await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RichNotificationService _richNotificationService = RichNotificationService();

  bool _isInitialized = false;

  /// Initialize the Notification Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request permissions
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
      // Even if declined, we might still want to initialize other parts if needed,
      // but usually push notifications won't work.
    }

    // 2. Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        // Show local notification
        _richNotificationService.showNotification(
          NotificationModel(
            id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            userId: _auth.currentUser?.uid ?? '',
            type: message.data['type'] ?? 'system',
            title: message.notification!.title ?? '',
            message: message.notification!.body ?? '',
            imageUrl: message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl,
            actionType: message.data['actionType'],
            actionData: message.data['actionData'],
            isRead: false,
            createdAt: DateTime.now(),
          ),
        );
      }
    });

    // 4. Update Token
    await _updateToken();

    // 5. Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // 6. Listen for auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _updateToken();
      }
    });

    _isInitialized = true;
  }

  /// Get current FCM token and save to Firestore
  Future<void> _updateToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }
  }

  /// Save the token to the user's document in Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving FCM token to Firestore: $e");
    }
  }

  /// Get the current FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Delete the token (e.g., on logout)
  Future<void> deleteToken() async {
     try {
      await _firebaseMessaging.deleteToken();
      final user = _auth.currentUser;
      if (user != null) {
         await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      }
    } catch (e) {
      debugPrint("Error deleting FCM token: $e");
    }
  }
}

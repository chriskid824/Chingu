import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

// Background message handler
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

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token Refreshed: $newToken');
      // Note: We can't update Firestore here without knowing userId.
      // The app should call updateFCMToken when user is logged in.
    });

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null) {
        // Show local notification using RichNotificationService
        RichNotificationService().showNotification(
          NotificationModel(
            id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            userId: '', // Not needed for local display
            type: message.data['type'] ?? 'system',
            title: notification.title ?? 'Notification',
            message: notification.body ?? '',
            imageUrl: android?.imageUrl ?? message.notification?.apple?.imageUrl,
            actionType: message.data['actionType'],
            actionData: message.data['actionData'],
            createdAt: DateTime.now(),
            isRead: false,
          ),
        );
      }
    });
  }

  /// Update FCM token in Firestore for the given user
  Future<void> updateFCMToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token updated for user $userId');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Get the current FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

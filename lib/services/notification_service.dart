import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

/// Notification Service - Handles FCM token management and foreground messages
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize notifications: request permission and setup listeners
  Future<void> initialize() async {
    // Request permission
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

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        // Show local notification using RichNotificationService
        // We construct a temporary NotificationModel for display
        final notification = NotificationModel(
          id: message.messageId ?? DateTime.now().toString(),
          userId: '', // Not needed for display only
          type: message.data['type'] ?? 'message',
          title: message.notification?.title ?? 'New Message',
          message: message.notification?.body ?? '',
          imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
          actionType: message.data['actionType'], // e.g., 'open_chat'
          actionData: message.data['actionData'] ?? message.data['chatRoomId'], // Use chatRoomId if present
          createdAt: DateTime.now(),
        );

        RichNotificationService().showNotification(notification);
      }
    });
  }

  /// Save FCM token to Firestore user document
  Future<void> saveToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('Saving FCM Token: $token');
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          debugPrint('FCM Token Refreshed: $newToken');
          _firestore.collection('users').doc(userId).update({
            'fcmToken': newToken,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
        });
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }
}

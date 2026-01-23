import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      // Get token
      try {
        String? token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
        }
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      // Listen to token refresh
      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

      // Listen to auth state changes to save token when user logs in
      _auth.authStateChanges().listen((user) {
        if (user != null) {
           _messaging.getToken().then((token) {
             if (token != null) _saveTokenToFirestore(token);
           });
        }
      });

      // Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          try {
             final notification = NotificationModel(
              id: message.messageId ?? DateTime.now().toString(),
              userId: _auth.currentUser?.uid ?? '',
              type: message.data['type'] ?? 'message',
              title: message.notification!.title ?? '',
              message: message.notification!.body ?? '',
              actionType: message.data['actionType'],
              actionData: message.data['actionData'],
              imageUrl: message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl,
              isRead: false,
              createdAt: DateTime.now(),
            );
            RichNotificationService().showNotification(notification);
          } catch (e) {
            debugPrint('Error showing foreground notification: $e');
          }
        }
      });

    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM token saved for user ${user.uid}');
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    }
  }

  Future<void> deleteToken() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
        await _messaging.deleteToken();
      } catch (e) {
        debugPrint('Error deleting FCM token: $e');
      }
    }
  }
}

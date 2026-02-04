import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../core/routes/app_router.dart';
import 'notification_ab_service.dart';
import 'rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationABService _abService = NotificationABService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  Future<void> initialize() async {
    // 1. Request permission
    NotificationSettings settings = await _messaging.requestPermission(
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

    // 2. Get Token and Update Firestore
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _updateFcmToken(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _updateFcmToken(newToken);
    });

    // Listen to Auth State Changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        try {
          String? token = await _messaging.getToken();
          if (token != null) {
            await _updateFcmToken(token);
          }
        } catch (e) {
          debugPrint('Error updating FCM token on auth change: $e');
        }
      }
    });

    // 3. Foreground Message Handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');

      _handleForegroundMessage(message);
    });

    // 4. Background Click Handling
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageOpenedApp(message);
    });

    // 5. Terminated State Click Handling
    try {
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
       debugPrint('Error getting initial message: $e');
    }
  }

  Future<void> _updateFcmToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Convert RemoteMessage to NotificationModel
    final notification = _createNotificationModel(message);

    // Show notification locally
    _richNotificationService.showNotification(notification);

    // Track Send
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _abService.logNotificationSend(userId, notification.type, notification.id);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
     final notification = _createNotificationModel(message);

     // Track Click
     final userId = FirebaseAuth.instance.currentUser?.uid;
     if (userId != null) {
       _abService.logNotificationClick(userId, notification.type, notification.id);
     }

     // Navigate
     final navigator = AppRouter.navigatorKey.currentState;
     if (navigator != null) {
       if (notification.actionType == 'open_chat') {
          navigator.pushNamed(AppRoutes.chatList);
       } else if (notification.actionType == 'view_event') {
          navigator.pushNamed(AppRoutes.eventDetail);
       } else if (notification.actionType == 'match_history') {
          navigator.pushNamed(AppRoutes.matchesList);
       } else {
          navigator.pushNamed(AppRoutes.notifications);
       }
     }
  }

  NotificationModel _createNotificationModel(RemoteMessage message) {
      final data = message.data;
      return NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        type: data['type'] ?? 'system',
        title: message.notification?.title ?? data['title'] ?? 'Notification',
        message: message.notification?.body ?? data['body'] ?? '',
        imageUrl: data['imageUrl'],
        actionType: data['actionType'],
        actionData: data['actionData'],
        createdAt: DateTime.now(),
      );
  }
}

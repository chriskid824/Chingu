import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/core/routes/app_router.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access other Firebase services, initialize them here
  // await Firebase.initializeApp();
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
  final RichNotificationService _richNotificationService = RichNotificationService();

  bool _isInitialized = false;
  NotificationModel? _pendingNotification;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize RichNotificationService (Local Notifications)
    await _richNotificationService.initialize();

    // Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted permission');

      // Update token if user is logged in
      _updateToken();

      // Listen to auth state changes
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          _updateToken();
        }
      });

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((String newToken) {
         final user = FirebaseAuth.instance.currentUser;
         if (user != null) {
           _firestoreService.updateFcmToken(user.uid, newToken);
         }
      });

      // Foreground Message
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');

          // Show local notification
          _richNotificationService.showNotification(
            _convertToNotificationModel(message)
          );
        } else if (message.data.isNotEmpty) {
           // Show notification for data-only messages in foreground
           _richNotificationService.showNotification(
              _convertToNotificationModel(message)
           );
        }
      });

      // Background Message (Tapped)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      // Terminated State (Tapped)
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        // Store the initial notification to be handled when UI is ready
        _pendingNotification = _convertToNotificationModel(initialMessage);
      }

      // Set background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    } else {
      debugPrint('User declined or has not accepted permission');
    }

    _isInitialized = true;
  }

  /// Check and process any pending notification (from terminated state)
  void checkPendingNotification() {
    if (_pendingNotification != null) {
      debugPrint('Processing pending notification: ${_pendingNotification!.id}');
      _handleNavigation(_pendingNotification!.actionType, _pendingNotification!.actionData);
      _pendingNotification = null;
    }
  }

  Future<void> _updateToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestoreService.updateFcmToken(user.uid, token);
      }
    }
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    _handleNavigation(actionType, actionData);
  }

  void _handleNavigation(String? actionType, String? actionData) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    if (actionType != null) {
      switch (actionType) {
        case 'open_chat':
          // Navigate to chat list (since detail needs args)
          navigator.pushNamed(AppRoutes.chatList);
          break;
        case 'view_event':
          navigator.pushNamed(AppRoutes.eventDetail);
          break;
        case 'match_history':
          navigator.pushNamed(AppRoutes.matchesList);
          break;
        default:
          navigator.pushNamed(AppRoutes.notifications);
          break;
      }
    } else {
      navigator.pushNamed(AppRoutes.notifications);
    }
  }

  NotificationModel _convertToNotificationModel(RemoteMessage message) {
     final data = message.data;
     final notification = message.notification;

     return NotificationModel(
       id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
       userId: FirebaseAuth.instance.currentUser?.uid ?? '',
       type: data['type'] ?? 'system',
       title: notification?.title ?? data['title'] ?? '通知',
       message: notification?.body ?? data['body'] ?? data['message'] ?? '',
       imageUrl: data['imageUrl'] ?? (notification?.android?.imageUrl),
       actionType: data['actionType'],
       actionData: data['actionData'],
       isRead: false,
       createdAt: DateTime.now(),
     );
  }
}

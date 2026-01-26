import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/routes/app_router.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';
import 'dart:convert';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
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

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle terminated state (App opened from terminated state)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      // Use addPostFrameCallback to ensure Navigator is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
         _handleMessage(initialMessage);
      });
    }

    // Handle background state (App opened from background state)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Handle foreground state
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        // Forward to RichNotificationService to display local notification
        // We construct a temporary NotificationModel from RemoteMessage
        // Since NotificationModel.fromRemoteMessage is missing, we map manually
         try {
           final notification = NotificationModel(
             id: message.messageId ?? DateTime.now().toString(),
             userId: '', // Not available in RemoteMessage usually, or in data
             type: message.data['type'] ?? 'system',
             title: message.notification?.title ?? '',
             message: message.notification?.body ?? '',
             imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
             actionType: message.data['actionType'],
             actionData: message.data['actionData'],
             createdAt: DateTime.now(),
           );
           RichNotificationService().showNotification(notification);
         } catch (e) {
           debugPrint('Error showing foreground notification: $e');
         }
      }
    });

    _isInitialized = true;
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'] as String?;
    final actionData = data['actionData'] as String?;

    _handleNavigation(actionType, actionData);
  }

  void _handleNavigation(String? actionType, String? actionData) {
    // Retry mechanism if navigator is not ready immediately (e.g. race condition)
    if (AppRouter.navigatorKey.currentState == null) {
      debugPrint('Navigator state is null. Retrying in 500ms...');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (AppRouter.navigatorKey.currentState != null) {
           _handleNavigation(actionType, actionData);
        } else {
           debugPrint('Navigator state is still null. Navigation aborted.');
        }
      });
      return;
    }

    final navigator = AppRouter.navigatorKey.currentState!;

    switch (actionType) {
      case 'open_chat':
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
  }
}

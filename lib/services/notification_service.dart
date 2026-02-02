import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationRoute {
  final String routeName;
  final Object? arguments;

  NotificationRoute(this.routeName, this.arguments);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final RichNotificationService _richNotificationService = RichNotificationService();

  Future<void> initialize() async {
    // Request permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showForegroundNotification(message);
      }
    });

    // Background message handler (when app is opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message);
    });
  }

  Future<NotificationRoute?> getInitialNotificationAction() async {
    try {
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        return _parseNotification(initialMessage);
      }
    } catch (e) {
      debugPrint('Error getting initial message: $e');
    }
    return null;
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      final model = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // Not needed for local display
        type: data['type'] ?? 'system',
        title: notification.title ?? '',
        message: notification.body ?? '',
        imageUrl: data['imageUrl'] ?? notification.android?.imageUrl ?? notification.apple?.imageUrl,
        actionType: data['actionType'],
        actionData: data['actionData'],
        createdAt: DateTime.now(),
      );

      _richNotificationService.showNotification(model);
    }
  }

  NotificationRoute? _parseNotification(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];

    if (actionType == 'open_chat') {
       return NotificationRoute(AppRoutes.mainNavigation, {'initialIndex': 3});
    } else if (actionType == 'view_event') {
       return NotificationRoute(AppRoutes.eventDetail, null);
    } else if (actionType == 'match_history') {
       return NotificationRoute(AppRoutes.matchesList, null);
    }

    // If no specific action, but we have a notification, assume notifications screen
    if (message.notification != null || data.isNotEmpty) {
       return NotificationRoute(AppRoutes.notifications, null);
    }

    return null;
  }

  void _handleNavigation(RemoteMessage message) {
    final route = _parseNotification(message);
    if (route != null) {
       AppRouter.navigatorKey.currentState?.pushNamed(route.routeName, arguments: route.arguments);
    }
  }
}

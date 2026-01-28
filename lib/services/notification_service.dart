import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  OverlayEntry? _overlayEntry;
  Timer? _timer;

  void initialize() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null || message.data.isNotEmpty) {
        final notification = _convertToNotificationModel(message);
        _showForegroundNotification(notification);
      }
    });
  }

  NotificationModel _convertToNotificationModel(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().toString(),
      userId: '', // Not used for display
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? message.data['title'] ?? 'Notification',
      message: message.notification?.body ?? message.data['message'] ?? '',
      imageUrl: message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );
  }

  void _showForegroundNotification(NotificationModel notification) {
    _removeNotification();

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: InAppNotification(
            notification: notification,
            onDismiss: _removeNotification,
            onTap: () {
              _removeNotification();
              _handleNavigation(notification);
            },
          ),
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);

    // Auto dismiss after 4 seconds
    _timer = Timer(const Duration(seconds: 4), () {
      _removeNotification();
    });
  }

  void _removeNotification() {
    _timer?.cancel();
    _timer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleNavigation(NotificationModel notification) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final actionType = notification.actionType;
    final actionData = notification.actionData;

    switch (actionType) {
      case 'open_chat':
        // Match RichNotificationService logic: navigate to chat list for now
        // as ChatDetailScreen requires complex arguments
        navigator.pushNamed(AppRoutes.chatList);
        break;
      case 'view_event':
        if (actionData != null) {
          // Ideally pass eventId, but EventDetailScreen might not accept it directly yet
          navigator.pushNamed(AppRoutes.eventDetail);
        }
        break;
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList);
        break;
      default:
        // Default navigation
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }
}

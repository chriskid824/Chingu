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

  OverlayEntry? _currentOverlayEntry;
  Timer? _dismissTimer;

  void initialize() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification == null) return;

    final notification = _convertToNotificationModel(message);
    _showInAppNotification(notification);
  }

  NotificationModel _convertToNotificationModel(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().toString(),
      userId: '', // Not needed for display
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? '',
      message: message.notification?.body ?? '',
      imageUrl: message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
      isRead: false,
    );
  }

  void _showInAppNotification(NotificationModel notification) {
    // Remove existing notification if any
    _removeCurrentNotification();

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _currentOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: InAppNotification(
            notification: notification,
            onDismiss: _removeCurrentNotification,
            onTap: () {
              _removeCurrentNotification();
              _handleNotificationTap(notification);
            },
          ),
        ),
      ),
    );

    overlayState.insert(_currentOverlayEntry!);

    // Auto dismiss after 4 seconds
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _removeCurrentNotification();
    });
  }

  void _removeCurrentNotification() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  }

  void _handleNotificationTap(NotificationModel notification) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final actionType = notification.actionType;
    // final actionData = notification.actionData; // Unused for now

    if (actionType != null) {
      switch (actionType) {
        case 'open_chat':
          navigator.pushNamed(AppRoutes.chatList);
          break;
        case 'view_event':
          navigator.pushNamed(AppRoutes.eventsList);
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
}

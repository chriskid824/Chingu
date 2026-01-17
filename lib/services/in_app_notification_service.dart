import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();

  factory InAppNotificationService() {
    return _instance;
  }

  InAppNotificationService._internal();

  OverlayEntry? _overlayEntry;
  Timer? _timer;

  void initialize() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Only show if notification payload exists (standard FCM behavior)
      // or if we decide to show data-only messages as banners.
      // Usually, for in-app banners, we want to show what the user would have seen in the system tray.
      if (message.notification != null) {
        final notification = _createNotificationFromMessage(message);
        showNotification(notification);
      }
    });
  }

  NotificationModel _createNotificationFromMessage(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // Not needed for display
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? '',
      message: message.notification?.body ?? '',
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl ?? message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );
  }

  void showNotification(NotificationModel notification) {
    _removeNotification(); // Remove existing if any

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -150.0, end: 0.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: child,
            );
          },
          child: InAppNotification(
            notification: notification,
            onDismiss: _removeNotification,
            onTap: () {
              _handleNavigation(notification);
              _removeNotification();
            },
          ),
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);

    // Auto dismiss after 4 seconds
    _timer = Timer(const Duration(seconds: 4), _removeNotification);
  }

  void _removeNotification() {
    _timer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleNavigation(NotificationModel notification) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final actionType = notification.actionType;
    // final actionData = notification.actionData; // Can be used for detailed navigation

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

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';
import 'rich_notification_service.dart';

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();

  factory InAppNotificationService() {
    return _instance;
  }

  InAppNotificationService._internal();

  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;

  void show(NotificationModel notification, {Duration duration = const Duration(seconds: 4)}) {
    // Dismiss any existing notification immediately
    _removeCurrentNotification();

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
            onDismiss: _removeCurrentNotification,
            onTap: () {
              _removeCurrentNotification();
              _handleTap(notification);
            },
          ),
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);

    _dismissTimer = Timer(duration, () {
      _removeCurrentNotification();
    });
  }

  void _removeCurrentNotification() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleTap(NotificationModel notification) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    if (notification.actionType != null) {
      // Delegate navigation to RichNotificationService
      RichNotificationService().performAction(
        notification.actionType!,
        notification.actionData,
        navigator,
      );
    }
  }
}

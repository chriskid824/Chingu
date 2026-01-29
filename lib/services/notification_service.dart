import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';
import 'rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;

  Future<void> initialize() async {
    // Request permission
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      final notification = _mapMessageToModel(message);
      _showOverlay(notification);
    }
  }

  NotificationModel _mapMessageToModel(RemoteMessage message) {
    // Determine type from data or default to system
    final type = message.data['type'] ?? 'system';

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // Not strictly needed for display
      type: type,
      title: message.notification?.title ?? '',
      message: message.notification?.body ?? '',
      imageUrl: message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );
  }

  void _showOverlay(NotificationModel notification) {
    _removeOverlay();

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          type: MaterialType.transparency,
          child: InAppNotification(
            notification: notification,
            onDismiss: _removeOverlay,
            onTap: () {
              _removeOverlay();
              if (notification.actionType != null) {
                final navigator = AppRouter.navigatorKey.currentState;
                if (navigator != null) {
                  RichNotificationService().performAction(
                    notification.actionType!,
                    notification.actionData,
                    navigator,
                  );
                }
              }
            },
          ),
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);

    // Auto dismiss after 4 seconds
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

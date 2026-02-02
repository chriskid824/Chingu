import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import 'rich_notification_service.dart';
import '../core/routes/app_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  OverlayEntry? _overlayEntry;
  Timer? _timer;

  Future<void> initialize() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification == null && message.data.isEmpty) return;

    final data = message.data;
    final notification = message.notification;

    // Determine type from data or default to 'system'
    final String type = data['type'] ?? 'system';

    final model = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // Not used for display in InAppNotification
      type: type,
      title: notification?.title ?? data['title'] ?? '通知',
      message: notification?.body ?? data['message'] ?? '',
      imageUrl: data['imageUrl'] ?? notification?.android?.imageUrl,
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: DateTime.now(),
    );

    _showInAppNotification(model);
  }

  void _showInAppNotification(NotificationModel notification) {
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
              RichNotificationService().handleNavigation(
                notification.actionType,
                notification.actionData,
                null, // In-app notification tap is generic
              );
            },
          ),
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);

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
}

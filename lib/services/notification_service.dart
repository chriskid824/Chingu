import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';
import '../widgets/in_app_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_onMessage);
  }

  void _onMessage(RemoteMessage message) {
    if (message.notification != null || message.data.isNotEmpty) {
      final notificationModel = _mapToNotificationModel(message);
      _showInAppNotification(notificationModel);
    }
  }

  NotificationModel _mapToNotificationModel(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    // Extract image URL
    String? imageUrl = data['imageUrl'];
    if (imageUrl == null && notification != null) {
      if (Platform.isAndroid) {
        imageUrl = notification.android?.imageUrl;
      } else if (Platform.isIOS) {
        imageUrl = notification.apple?.imageUrl;
      }
    }

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? '通知',
      message: notification?.body ?? data['message'] ?? data['body'] ?? '',
      imageUrl: imageUrl,
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: message.sentTime ?? DateTime.now(),
      isRead: false,
    );
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
        child: InAppNotification(
          notification: notification,
          onDismiss: _removeNotification,
          onTap: () {
            _removeNotification();
            _handleNavigation(notification);
          },
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);

    // Auto dismiss after 5 seconds
    _dismissTimer = Timer(const Duration(seconds: 5), _removeNotification);
  }

  void _removeNotification() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleNavigation(NotificationModel notification) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final actionType = notification.actionType;
    // actionData is available but currently unused in switch, similar to RichNotificationService logic
    // final actionData = notification.actionData;

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

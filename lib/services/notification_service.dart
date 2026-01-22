import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/routes/app_router.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  OverlayEntry? _currentOverlayEntry;
  Timer? _dismissTimer;

  Future<void> initialize() async {
    // 監聽前景通知
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification == null) return;

    final notificationModel = _convertToNotificationModel(message);
    _showInAppNotification(notificationModel);
  }

  NotificationModel _convertToNotificationModel(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().toString(),
      userId: '', // 前景顯示不需要 userId
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? '',
      message: message.notification?.body ?? '',
      imageUrl: message.data['imageUrl'] ?? message.notification?.android?.imageUrl,
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );
  }

  void _showInAppNotification(NotificationModel notification) {
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

    // 自動消失
    _dismissTimer = Timer(const Duration(seconds: 4), _removeCurrentNotification);
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

    // 簡單的導航邏輯
    if (notification.actionType == 'open_chat') {
         navigator.pushNamed(AppRoutes.chatList);
    } else if (notification.actionType == 'view_event') {
         navigator.pushNamed(AppRoutes.eventDetail);
    } else {
         navigator.pushNamed(AppRoutes.notifications);
    }
  }
}

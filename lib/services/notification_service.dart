import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';
import '../widgets/in_app_notification.dart';
import 'rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  bool _isInitialized = false;
  OverlayEntry? _currentOverlayEntry;
  Timer? _dismissTimer;

  /// 初始化前景通知監聽
  void initialize() {
    if (_isInitialized) return;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showInAppNotification(message);
    });

    _isInitialized = true;
  }

  /// 顯示應用內通知
  void _showInAppNotification(RemoteMessage message) {
    // 移除當前顯示的通知
    _removeCurrentNotification();

    // 轉換 RemoteMessage 為 NotificationModel
    final notificationModel = _mapRemoteMessageToModel(message);

    // 獲取 OverlayState
    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    // 創建 OverlayEntry
    _currentOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(begin: const Offset(0, -1), end: Offset.zero),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, offset, child) {
              return Transform.translate(
                offset: Offset(0, offset.dy * 100), // 簡單的位移效果
                child: child,
              );
            },
            child: InAppNotification(
              notification: notificationModel,
              onDismiss: _removeCurrentNotification,
              onTap: () {
                _removeCurrentNotification();
                // 使用 RichNotificationService 處理導航
                RichNotificationService().handleNavigation(
                  notificationModel.actionType,
                  notificationModel.actionData,
                  null,
                );
              },
            ),
          ),
        ),
      ),
    );

    // 插入 Overlay
    overlayState.insert(_currentOverlayEntry!);

    // 設定自動消失定時器 (5秒)
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      _removeCurrentNotification();
    });
  }

  /// 移除當前通知
  void _removeCurrentNotification() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    if (_currentOverlayEntry != null) {
      _currentOverlayEntry!.remove();
      _currentOverlayEntry = null;
    }
  }

  /// 將 RemoteMessage 映射為 NotificationModel
  NotificationModel _mapRemoteMessageToModel(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? '',
      message: notification?.body ?? data['message'] ?? data['body'] ?? '',
      imageUrl: data['imageUrl'] ?? data['image'],
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: DateTime.now(),
    );
  }
}

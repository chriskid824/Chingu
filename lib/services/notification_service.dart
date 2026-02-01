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

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;

  /// 初始化通知服務
  Future<void> initialize() async {
    // 請求權限（雖然通常在 Onboarding 處理，但確保一下無妨）
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 監聽前景訊息
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// 處理前景訊息
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');

    // 構建 NotificationModel
    // 優先使用 data 中的欄位，若無則使用 notification 物件中的內容
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: message.data['userId'] ?? '',
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? message.data['title'] ?? '新通知',
      message: message.notification?.body ?? message.data['message'] ?? '',
      imageUrl: message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      isRead: false,
      createdAt: DateTime.now(),
    );

    _showInAppNotification(notification);
  }

  /// 顯示應用內通知橫幅
  void _showInAppNotification(NotificationModel notification) {
    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    // 移除舊的通知（如果有的話）
    _removeNotification();

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
              // 使用 RichNotificationService 的導航邏輯
              RichNotificationService().handleNavigation(
                notification.actionType,
                notification.actionData,
                null, // actionId
              );
            },
          ),
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);

    // 自動消失計時器
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _removeNotification();
    });
  }

  /// 移除通知
  void _removeNotification() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

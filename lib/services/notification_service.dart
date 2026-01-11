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

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;

  /// 初始化通知服務
  Future<void> initialize() async {
    // 請求通知權限
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 監聽前景訊息
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showForegroundNotification(message);
      }
    });
  }

  /// 顯示前景通知橫幅
  void _showForegroundNotification(RemoteMessage message) {
    // 將 RemoteMessage 轉換為 NotificationModel
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // 前景顯示不需要 userId
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? '新通知',
      message: message.notification?.body ?? '',
      imageUrl: message.notification?.android?.imageUrl ??
               message.notification?.apple?.imageUrl ??
               message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );

    _showOverlay(notification);
  }

  /// 顯示 Overlay
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
          color: Colors.transparent,
          child: InAppNotification(
            notification: notification,
            onDismiss: _removeOverlay,
            onTap: () => _handleTap(notification),
          ),
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);

    // 5秒後自動消失
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      _removeOverlay();
    });
  }

  /// 移除 Overlay
  void _removeOverlay() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
    }
    _overlayEntry = null;
  }

  /// 處理點擊事件
  void _handleTap(NotificationModel notification) {
    _removeOverlay();

    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    // 根據 actionType 導航
    final actionType = notification.actionType;
    final actionData = notification.actionData;

    if (actionType != null) {
      switch (actionType) {
        case 'open_chat':
          // 如果需要傳遞參數，可以在這裡解析 actionData
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
    } else {
      navigator.pushNamed(AppRoutes.notifications);
    }
  }
}

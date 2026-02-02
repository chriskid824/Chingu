import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  OverlayEntry? _currentOverlay;

  /// 初始化通知服務
  Future<void> initialize() async {
    // 設置前景訊息監聽器
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 如果需要，可以在這裡請求權限（通常在 Onboarding 流程中已經請求過）
    // await FirebaseMessaging.instance.requestPermission();
  }

  /// 處理前景訊息
  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      // 構建 NotificationModel
      // 注意：RemoteMessage 的結構與 NotificationModel 略有不同，需要適配
      final notification = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // 前景展示時不需要 userId
        type: message.data['type'] ?? 'system',
        title: message.notification?.title ?? '',
        message: message.notification?.body ?? '',
        imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl ?? message.data['imageUrl'],
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
        createdAt: DateTime.now(),
      );

      showInAppNotification(notification);
    }
  }

  /// 顯示應用內通知橫幅
  void showInAppNotification(NotificationModel notification) {
    // 如果已有顯示中的通知，先移除
    _removeCurrentOverlay();

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: _InAppNotificationWrapper(
          notification: notification,
          onDismiss: _removeCurrentOverlay,
          onTap: () {
            _removeCurrentOverlay();
            // 使用 RichNotificationService 處理導航
            RichNotificationService().handleNavigation(
              notification.actionType,
              notification.actionData,
              null,
            );
          },
        ),
      ),
    );

    overlayState.insert(_currentOverlay!);
  }

  void _removeCurrentOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

/// 處理動畫和自動消失的包裝器
class _InAppNotificationWrapper extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _InAppNotificationWrapper({
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_InAppNotificationWrapper> createState() => _InAppNotificationWrapperState();
}

class _InAppNotificationWrapperState extends State<_InAppNotificationWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // 5秒後自動消失
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isDismissing) {
        _dismiss();
      }
    });
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: InAppNotification(
        notification: widget.notification,
        onDismiss: _dismiss,
        onTap: () {
          _dismiss().then((_) => widget.onTap());
        },
      ),
    );
  }
}

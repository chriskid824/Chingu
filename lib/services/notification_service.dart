import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  OverlayEntry? _currentOverlayEntry;

  /// 初始化通知服務
  Future<void> initialize() async {
    // 監聽前景訊息
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 處理應用程式從背景開啟
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 檢查是否有初始訊息 (App 被終止後開啟)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// 處理前景收到的訊息
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');

    if (message.notification != null || message.data.isNotEmpty) {
      final notification = _convertToNotificationModel(message);
      showInAppNotification(notification);
    }
  }

  /// 處理從通知開啟應用程式
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App opened from notification: ${message.messageId}');
    final notification = _convertToNotificationModel(message);
    _handleNavigation(notification);
  }

  /// 將 RemoteMessage 轉換為 NotificationModel
  NotificationModel _convertToNotificationModel(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: data['userId'] ?? '', // 如果 data 中沒有 userId，則為空
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? '新通知',
      message: notification?.body ?? data['message'] ?? '',
      imageUrl: data['imageUrl'],
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: message.sentTime ?? DateTime.now(),
      isRead: false,
    );
  }

  /// 顯示應用內通知橫幅
  void showInAppNotification(NotificationModel notification) {
    // 如果已有顯示中的通知，先移除
    _removeCurrentNotification();

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _currentOverlayEntry = OverlayEntry(
      builder: (context) => _NotificationOverlay(
        notification: notification,
        onDismiss: _removeCurrentNotification,
        onTap: () {
          _removeCurrentNotification();
          _handleNavigation(notification);
        },
      ),
    );

    overlayState.insert(_currentOverlayEntry!);
  }

  void _removeCurrentNotification() {
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  }

  /// 處理導航邏輯
  void _handleNavigation(NotificationModel notification) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final actionType = notification.actionType;
    final actionData = notification.actionData;

    switch (actionType) {
      case 'open_chat':
        // 導航到聊天列表
        navigator.pushNamed(AppRoutes.chatList);
        break;
      case 'view_event':
        // 導航到活動詳情
        if (actionData != null) {
             // 這裡假設 EventDetailScreen 可以處理參數，或者我們只是導航到列表
             // 根據 RichNotificationService 的邏輯，它導航到 eventDetail
             navigator.pushNamed(AppRoutes.eventDetail);
        } else {
             navigator.pushNamed(AppRoutes.eventsList);
        }
        break;
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList);
        break;
      default:
        // 預設導航到通知頁面
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }
}

/// 私有組件：處理通知動畫與自動消失
class _NotificationOverlay extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _NotificationOverlay({
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    // 開始進場動畫
    _controller.forward();

    // 設定自動消失計時器 (4秒)
    _autoDismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _animateOut();
      }
    });
  }

  void _animateOut() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: InAppNotification(
          notification: widget.notification,
          onDismiss: _animateOut,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

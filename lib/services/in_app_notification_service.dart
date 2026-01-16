import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();

  factory InAppNotificationService() => _instance;

  InAppNotificationService._internal();

  OverlayEntry? _overlayEntry;
  Timer? _timer;

  /// 顯示應用內通知
  void showNotification(NotificationModel notification) {
    // 如果已有通知，先移除（無動畫）
    _removeCurrentNotification();

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _InAppNotificationContainer(
        notification: notification,
        onDismiss: () => _handleDismiss(),
        onTap: () => _handleTap(notification),
      ),
    );

    overlayState.insert(_overlayEntry!);

    // 5秒後自動移除
    _timer = Timer(const Duration(seconds: 5), () {
      _handleDismiss();
    });
  }

  /// 移除當前通知
  void dismissNotification() {
    _handleDismiss();
  }

  void _removeCurrentNotification() {
    _timer?.cancel();
    _timer = null;
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  /// 處理移除（這裡可以觸發退出動畫，目前簡化為直接移除，
  /// 若要支援退出動畫，需通過 Key 或 Stream 通知 Widget）
  ///
  /// 備註：_InAppNotificationContainer 內部有處理滑出手勢的動畫，
  /// 但自動消失或外部呼叫 dismiss 時，目前是直接移除。
  void _handleDismiss() {
    _removeCurrentNotification();
  }

  void _handleTap(NotificationModel notification) {
    // 點擊後移除通知
    _removeCurrentNotification();

    // 執行導航
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    // 根據 actionType 導航
    if (notification.actionType != null) {
      switch (notification.actionType) {
        case 'open_chat':
          navigator.pushNamed(AppRoutes.chatList);
          break;
        case 'view_event':
          navigator.pushNamed(AppRoutes.eventDetail); // 注意：可能需要參數
          break;
        case 'match_history':
          navigator.pushNamed(AppRoutes.matchesList);
          break;
        default:
          navigator.pushNamed(AppRoutes.notifications);
      }
    } else {
      navigator.pushNamed(AppRoutes.notifications);
    }
  }
}

class _InAppNotificationContainer extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _InAppNotificationContainer({
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_InAppNotificationContainer> createState() => _InAppNotificationContainerState();
}

class _InAppNotificationContainerState extends State<_InAppNotificationContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _animateOutAndDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  Future<void> _animateOutAndTap() async {
    await _controller.reverse();
    widget.onTap();
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
          onDismiss: _animateOutAndDismiss,
          onTap: _animateOutAndTap,
        ),
      ),
    );
  }
}

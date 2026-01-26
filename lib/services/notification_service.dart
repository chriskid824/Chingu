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

  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _isInitialized = true;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // 只有當包含 notification 或 data 時才處理
    if (message.notification != null || message.data.isNotEmpty) {
      final notification = _convertToNotificationModel(message);
      _showInAppNotification(notification);
    }
  }

  NotificationModel _convertToNotificationModel(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // 前景顯示不需要 userId
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? 'Notification',
      message: notification?.body ?? data['message'] ?? '',
      imageUrl: data['imageUrl'] ?? notification?.android?.imageUrl ?? notification?.apple?.imageUrl,
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: message.sentTime ?? DateTime.now(),
    );
  }

  void _showInAppNotification(NotificationModel notification) {
    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _InAppNotificationWrapper(
          notification: notification,
          onDismiss: () {
            if (overlayEntry.mounted) {
               overlayEntry.remove();
            }
          },
          onTap: () {
            if (overlayEntry.mounted) {
               overlayEntry.remove();
            }
            _handleNavigation(notification);
          },
        );
      },
    );

    overlayState.insert(overlayEntry);
  }

  void _handleNavigation(NotificationModel notification) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final actionType = notification.actionType;

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
        // 預設導航到通知頁面
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }
}

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
  Timer? _timer;

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

    // 4秒後自動消失
    _timer = Timer(const Duration(seconds: 4), () {
        _dismiss();
    });
  }

  void _dismiss() async {
      _timer?.cancel();
      await _controller.reverse();
      widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
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
        child: Material(
            type: MaterialType.transparency,
            child: InAppNotification(
                notification: widget.notification,
                onDismiss: _dismiss,
                onTap: () {
                     _timer?.cancel();
                     widget.onTap();
                },
            ),
        ),
      ),
    );
  }
}

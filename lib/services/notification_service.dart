import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';
import '../widgets/in_app_notification.dart';
import 'rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  void _showForegroundNotification(RemoteMessage message) {
    if (message.notification == null) return;

    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // Not needed for display
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? 'Notification',
      message: message.notification?.body ?? '',
      imageUrl: message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
      isRead: false,
    );

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedNotificationOverlay(
        notification: notification,
        onDismiss: () {
          overlayEntry.remove();
        },
        onTap: () {
          overlayEntry.remove();
          RichNotificationService().handleNotificationAction(
            notification.actionType,
            notification.actionData,
            null,
          );
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _AnimatedNotificationOverlay extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _AnimatedNotificationOverlay({
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_AnimatedNotificationOverlay> createState() => _AnimatedNotificationOverlayState();
}

class _AnimatedNotificationOverlayState extends State<_AnimatedNotificationOverlay> with SingleTickerProviderStateMixin {
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

    // Auto dismiss
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _timer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) { // Check mounted before calling callback just in case
         widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
          onDismiss: _dismiss,
          onTap: () {
            _timer?.cancel(); // Cancel timer on tap
            widget.onTap();
          },
        ),
      ),
    );
  }
}

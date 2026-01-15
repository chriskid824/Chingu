import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';
import '../services/rich_notification_service.dart';

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();

  factory InAppNotificationService() => _instance;

  InAppNotificationService._internal();

  OverlayEntry? _overlayEntry;
  Timer? _timer;
  GlobalKey<_SlideInNotificationState>? _notificationKey;
  final Duration _displayDuration = const Duration(seconds: 4);
  final Duration _animationDuration = const Duration(milliseconds: 300);

  void show(NotificationModel notification) {
    _removeCurrentNotification();

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _notificationKey = GlobalKey<_SlideInNotificationState>();

    _overlayEntry = OverlayEntry(
      builder: (context) => _SlideInNotification(
        key: _notificationKey,
        notification: notification,
        duration: _animationDuration,
        onDismiss: dismiss,
        onTap: () {
           // Handle tap
           dismiss();
           if (notification.actionType != null || notification.actionData != null) {
              // Use RichNotificationService to handle navigation logic
              RichNotificationService().handleNavigation(
                  notification.actionType,
                  notification.actionData,
                  null // actionId
              );
           }
        },
      ),
    );

    overlayState.insert(_overlayEntry!);

    _timer = Timer(_displayDuration, () {
      dismiss();
    });
  }

  Future<void> dismiss() async {
    _timer?.cancel();
    _timer = null;

    // Check if key and current state exist to perform animation
    if (_notificationKey?.currentState != null) {
      await _notificationKey!.currentState!.animateOut();
    }

    _removeCurrentNotification();
  }

  void _removeCurrentNotification() {
    _timer?.cancel();
    _timer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _notificationKey = null;
  }
}

class _SlideInNotification extends StatefulWidget {
  final NotificationModel notification;
  final Duration duration;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _SlideInNotification({
    super.key,
    required this.notification,
    required this.duration,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_SlideInNotification> createState() => _SlideInNotificationState();
}

class _SlideInNotificationState extends State<_SlideInNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
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

  Future<void> animateOut() async {
    if (!mounted) return;
    try {
      await _controller.reverse().orCancel;
    } catch (e) {
      // Ignore animation errors
    }
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
          color: Colors.transparent,
          child: InAppNotification(
            notification: widget.notification,
            onDismiss: widget.onDismiss,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

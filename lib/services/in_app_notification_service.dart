import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';
import '../widgets/in_app_notification.dart';

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();

  factory InAppNotificationService() {
    return _instance;
  }

  InAppNotificationService._internal();

  OverlayEntry? _overlayEntry;

  void show(NotificationModel notification) {
    _removeCurrent();

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    final key = GlobalKey<_NotificationOverlayState>();

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _NotificationOverlay(
        key: key,
        notification: notification,
        onTap: () {
           _handleNavigation(notification);
           key.currentState?.animateOut();
        },
        onDismiss: () {
           key.currentState?.animateOut();
        },
        onRemove: () {
           if (_overlayEntry == entry) {
              entry.remove();
              _overlayEntry = null;
           }
        },
      ),
    );

    _overlayEntry = entry;
    overlayState.insert(entry);
  }

  void _removeCurrent() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (e) {
        // Ignore if already removed
      }
      _overlayEntry = null;
    }
  }

  void _handleNavigation(NotificationModel notification) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final actionType = notification.actionType;
    final actionData = notification.actionData;

    if (actionType != null) {
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
          navigator.pushNamed(AppRoutes.notifications);
          break;
      }
    } else {
        navigator.pushNamed(AppRoutes.notifications);
    }
  }
}

class _NotificationOverlay extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback onRemove;

  const _NotificationOverlay({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay> with SingleTickerProviderStateMixin {
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

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onRemove();
      }
    });

    // Auto dismiss
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) animateOut();
    });
  }

  void animateOut() {
    _timer?.cancel();
    if (mounted && !_controller.isDismissed) {
      _controller.reverse();
    }
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
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: InAppNotification(
            notification: widget.notification,
            onTap: widget.onTap,
            onDismiss: widget.onDismiss,
          ),
        ),
      ),
    );
  }
}

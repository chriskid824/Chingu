import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';
import 'rich_notification_service.dart';

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();

  factory InAppNotificationService() => _instance;

  InAppNotificationService._internal();

  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;
  GlobalKey<_InAppNotificationWrapperState>? _wrapperKey;

  void showNotification(NotificationModel notification) {
    // If a notification is already showing, remove it immediately (no animation)
    // so the new one can appear.
    _removeCurrentNotification(force: true);

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _wrapperKey = GlobalKey<_InAppNotificationWrapperState>();

    _overlayEntry = OverlayEntry(
      builder: (context) => _InAppNotificationWrapper(
        key: _wrapperKey,
        notification: notification,
        onDismiss: () => _removeCurrentNotification(force: true), // Callback when animation finishes or user dismisses
        onTap: () {
          // Navigate then dismiss
          RichNotificationService().handleNavigation(
            notification.actionType,
            notification.actionData,
            null,
          );
           // We can trigger dismiss animation here too, or just remove.
           // Let's trigger animation for better UX.
           _wrapperKey?.currentState?.dismiss();
        },
      ),
    );

    overlayState.insert(_overlayEntry!);

    // Auto dismiss after 4 seconds
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      // Trigger exit animation
      _wrapperKey?.currentState?.dismiss();
    });
  }

  void _removeCurrentNotification({bool force = false}) {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _wrapperKey = null;
  }
}

class _InAppNotificationWrapper extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _InAppNotificationWrapper({
    Key? key,
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  }) : super(key: key);

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> dismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;
    try {
      await _controller.reverse();
    } catch (e) {
      // Controller might be disposed if removed abruptly
    }
    if (mounted) {
      widget.onDismiss();
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
            child: Dismissible(
                key: ValueKey(widget.notification.id),
                direction: DismissDirection.up,
                onDismissed: (_) {
                   // Dismissible already handled the animation visually (mostly), but we need to cleanup
                   widget.onDismiss();
                },
                child: InAppNotification(
                    notification: widget.notification,
                    onDismiss: () => dismiss(),
                    onTap: widget.onTap,
                )
            )
        ),
      ),
    );
  }
}

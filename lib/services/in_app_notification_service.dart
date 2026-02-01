import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();

  factory InAppNotificationService() {
    return _instance;
  }

  InAppNotificationService._internal();

  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;
  GlobalKey<_NotificationOverlayState>? _overlayKey;

  /// Show a notification at the top of the screen
  void show(NotificationModel notification, {Duration duration = const Duration(seconds: 4)}) {
    _dismissImmediately(); // Dismiss any existing notification immediately

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayKey = GlobalKey<_NotificationOverlayState>();
    _overlayEntry = OverlayEntry(
      builder: (context) => _NotificationOverlay(
        key: _overlayKey,
        notification: notification,
        onDismiss: _dismissImmediately,
        onTap: () {
          _dismissImmediately();
          // Handle navigation if needed, or let the caller handle it.
        },
      ),
    );

    overlayState.insert(_overlayEntry!);

    _dismissTimer = Timer(duration, () {
      _animateOutAndDismiss();
    });
  }

  void _animateOutAndDismiss() {
    if (_overlayKey?.currentState != null) {
      _overlayKey!.currentState!.reverseAndDismiss();
    } else {
      _dismissImmediately();
    }
  }

  void _dismissImmediately() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _overlayKey = null;
    }
  }
}

class _NotificationOverlay extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _NotificationOverlay({
    super.key,
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay> with SingleTickerProviderStateMixin {
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

  Future<void> reverseAndDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
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
            onDismiss: () => reverseAndDismiss(),
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  OverlayEntry? _overlayEntry;

  Future<void> initialize() async {
    // Listen to foreground messages
    // Permissions are handled by NotificationPermissionScreen or RichNotificationService
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Check if notification part exists, or use data
    final String title = message.notification?.title ?? '';
    final String body = message.notification?.body ?? '';

    // If both title and body are empty, check data
    if (title.isEmpty && body.isEmpty && message.data.isEmpty) {
        return;
    }

    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().toString(),
      userId: '', // Not used for display
      type: message.data['type'] ?? 'system',
      title: title.isNotEmpty ? title : (message.data['title'] ?? ''),
      message: body.isNotEmpty ? body : (message.data['message'] ?? ''),
      imageUrl: message.notification?.android?.imageUrl ?? message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );

    _showInAppNotification(notification);
  }

  void _showInAppNotification(NotificationModel notification) {
    // Remove existing if any
    _overlayEntry?.remove();
    _overlayEntry = null;

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: _SlideInNotification(
            notification: notification,
            onDismiss: _dismissNotification,
            onTap: () {
                _dismissNotification();
                RichNotificationService().handleNavigation(
                  notification.actionType,
                  notification.actionData,
                  null
                );
            },
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  void _dismissNotification() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _SlideInNotification extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _SlideInNotification({
    required this.notification,
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

    _controller.forward();

    // Auto dismiss
    Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
            _reverseAndDismiss();
        }
    });
  }

  void _reverseAndDismiss() async {
      if (!mounted) return;
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
        onTap: widget.onTap,
        onDismiss: _reverseAndDismiss,
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;

  void initialize() {
    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');

    // Parse message to NotificationModel
    final notification = _parsingFromMessage(message);
    if (notification != null) {
      _showInAppNotification(notification);
    }
  }

  NotificationModel? _parsingFromMessage(RemoteMessage message) {
    try {
      final data = message.data;
      final notification = message.notification;

      // Ensure we have a title and message either from notification payload or data
      final String title = notification?.title ?? data['title'] ?? 'New Notification';
      final String body = notification?.body ?? data['message'] ?? data['body'] ?? '';

      if (body.isEmpty) return null;

      final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      return NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: data['type'] ?? 'system',
        title: title,
        message: body,
        imageUrl: data['imageUrl'],
        actionType: data['actionType'],
        actionData: data['actionData'],
        isRead: false,
        createdAt: message.sentTime ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing notification message: $e');
      return null;
    }
  }

  void _showInAppNotification(NotificationModel notification) {
    // Remove existing notification if any
    _removeNotification();

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _SlideInNotification(
        notification: notification,
        onDismiss: _removeNotification,
        onTap: () {
          _removeNotification();
          _handleNavigation(notification);
        },
      ),
    );

    overlayState.insert(_overlayEntry!);

    // Auto dismiss after 4 seconds
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _removeNotification();
    });
  }

  void _removeNotification() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
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

class _SlideInNotification extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _SlideInNotification({
    Key? key,
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  }) : super(key: key);

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

import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;
  GlobalKey<_AnimatedNotificationOverlayState>? _overlayKey;

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    _isInitialized = true;
  }

  /// Handle incoming foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      final notification = _convertToNotificationModel(message);
      showInAppNotification(notification);
    }
  }

  /// Convert RemoteMessage to NotificationModel
  NotificationModel _convertToNotificationModel(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // Not needed for display
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? '',
      message: message.notification?.body ?? '',
      imageUrl: message.data['imageUrl'] ?? message.notification?.android?.imageUrl,
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );
  }

  /// Show in-app notification banner
  void showInAppNotification(NotificationModel notification) {
    // Remove existing notification if any
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _dismissTimer?.cancel();
    }

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayKey = GlobalKey<_AnimatedNotificationOverlayState>();

    _overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedNotificationOverlay(
        key: _overlayKey,
        notification: notification,
        onDismiss: _animateOutAndRemove,
        onTap: () {
          _animateOutAndRemove();
          _handleNavigation(notification);
        },
      ),
    );

    overlayState.insert(_overlayEntry!);

    // Auto dismiss after 4 seconds
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _animateOutAndRemove();
    });
  }

  void _animateOutAndRemove() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    if (_overlayKey?.currentState != null) {
      _overlayKey!.currentState!.animateOut().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _overlayKey = null;
      });
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  void _handleNavigation(NotificationModel notification) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final actionType = notification.actionType;
    final actionData = notification.actionData;

    // Try to parse actionData if it exists
    dynamic arguments;
    if (actionData != null) {
      try {
        arguments = json.decode(actionData);
      } catch (e) {
        // If not JSON, use as is (e.g. simple ID string)
        arguments = actionData;
      }
    }

    if (actionType != null) {
      switch (actionType) {
        case 'open_chat':
          // ChatDetailScreen requires a Map with 'chatRoomId' and 'otherUser' (UserModel).
          // Since we might only have chatRoomId in notification, we default to ChatList
          // to avoid "infinite loading" or crashes due to missing data.
          navigator.pushNamed(AppRoutes.chatList);
          break;
        case 'view_event':
          // Pass arguments just in case EventDetailScreen supports them in the future
          navigator.pushNamed(AppRoutes.eventDetail, arguments: arguments);
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

class _AnimatedNotificationOverlay extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _AnimatedNotificationOverlay({
    super.key,
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

  Future<void> animateOut() async {
    await _controller.reverse();
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
        child: InAppNotification(
          notification: widget.notification,
          onDismiss: widget.onDismiss,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

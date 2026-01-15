import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';
import 'firestore_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  OverlayEntry? _overlayEntry;
  Timer? _overlayTimer;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle token
      _setupToken();
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    _isInitialized = true;
  }

  Future<void> _setupToken() async {
    // Get the token each time the application loads
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Any time the token refreshes, store it in the database and current user
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestoreService.updateFcmToken(user.uid, token);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
    }

    final notification = _convertToNotificationModel(message);
    _showInAppNotification(notification);
  }

  NotificationModel _convertToNotificationModel(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? message.data['title'] ?? '通知',
      message: message.notification?.body ?? message.data['message'] ?? '',
      imageUrl: message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: message.sentTime ?? DateTime.now(),
    );
  }

  void _showInAppNotification(NotificationModel notification) {
    // Dismiss existing notification if any
    _removeNotification();

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: _SlideDownNotification(
            child: InAppNotification(
              notification: notification,
              onDismiss: _removeNotification,
              onTap: () {
                _removeNotification();
                _handleNotificationTap(notification);
              },
            ),
            onDismiss: _removeNotification,
          ),
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);

    // Auto dismiss after 5 seconds
    _overlayTimer = Timer(const Duration(seconds: 5), () {
      _removeNotification();
    });
  }

  void _removeNotification() {
    _overlayTimer?.cancel();
    _overlayTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleNotificationTap(NotificationModel notification) {
     final navigator = AppRouter.navigatorKey.currentState;
     if (navigator == null) return;

     final actionType = notification.actionType;
     final actionData = notification.actionData;

     // Basic navigation handling - consistent with RichNotificationService
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
         // If no specific action, maybe open notifications list
         navigator.pushNamed(AppRoutes.notifications);
         break;
     }
  }
}

class _SlideDownNotification extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const _SlideDownNotification({required this.child, required this.onDismiss});

  @override
  _SlideDownNotificationState createState() => _SlideDownNotificationState();
}

class _SlideDownNotificationState extends State<_SlideDownNotification> with SingleTickerProviderStateMixin {
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
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}

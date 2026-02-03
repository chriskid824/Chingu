import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';
import '../widgets/in_app_notification.dart';
import 'rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  OverlayEntry? _overlayEntry;
  Timer? _overlayTimer;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen to background message tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    }
  }

  Future<void> checkInitialMessage() async {
    // Check for initial message
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null || message.data.isNotEmpty) {
      final notification = _convertToNotificationModel(message);
      _showInAppNotification(notification);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
     final notification = _convertToNotificationModel(message);
     RichNotificationService().handleNavigation(
       notification.actionType,
       notification.actionData,
       notification.id,
     );
  }

  void _showInAppNotification(NotificationModel notification) {
    _dismissInAppNotification();

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: AnimatedInAppNotification(
          notification: notification,
          onDismiss: _dismissInAppNotification,
          onTap: () {
            RichNotificationService().handleNavigation(
               notification.actionType,
               notification.actionData,
               notification.id,
             );
          },
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);

    // Auto dismiss after 4 seconds
    _overlayTimer = Timer(const Duration(seconds: 4), () {
      _dismissInAppNotification();
    });
  }

  void _dismissInAppNotification() {
    _overlayTimer?.cancel();
    _overlayTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  NotificationModel _convertToNotificationModel(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '',
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? '通知',
      message: notification?.body ?? data['message'] ?? '',
      imageUrl: data['imageUrl'] ?? (notification?.android?.imageUrl),
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: DateTime.now(),
    );
  }
}

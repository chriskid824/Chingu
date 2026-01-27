import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'rich_notification_service.dart';
import 'notification_ab_service.dart';
import '../models/notification_model.dart';
import 'dart:math';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationABService _abService = NotificationABService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    // Get Token (Optional: You might want to save this to your server/user profile)
    String? token = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');

    // Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // If it has a notification payload, the SDK might handle display (or we show a local one).
        // For A/B testing consistency, we prefer data messages to construct the UI ourselves.
        // But if it's here, we track it if we can identify it.
      }

      await _handleIncomingMessage(message);
    });

    // Background Message Opened Handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageOpened(message);
    });

    // Terminated State Message Opened Handler
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpened(initialMessage);
    }

    _isInitialized = true;
  }

  /// Handles incoming messages (foreground) to display and track.
  Future<void> _handleIncomingMessage(RemoteMessage message) async {
    final data = message.data;
    final String? type = data['type'];
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return;

    // If type is present, we assume it's an A/B testable notification
    if (type != null) {
      // 1. Generate Content
      // Map string type to enum
      NotificationType? notificationType;
      try {
        notificationType = NotificationType.values.firstWhere(
          (e) => e.toString().split('.').last == type,
          orElse: () => NotificationType.system,
        );
      } catch (e) {
        notificationType = NotificationType.system;
      }

      final content = _abService.getContent(
        userId,
        notificationType,
        params: data,
      );

      // 2. Create Notification Model
      // Use existing ID or generate one
      final notificationId = message.messageId ??
          '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';

      final notification = NotificationModel(
        id: notificationId,
        userId: userId,
        type: type,
        title: content.title,
        message: content.body,
        imageUrl: data['imageUrl'],
        actionType: data['actionType'],
        actionData: data['actionData'],
        createdAt: DateTime.now(),
      );

      // 3. Show Notification
      await _richNotificationService.showNotification(notification);

      // 4. Track Sent
      await _abService.trackNotificationSent(userId, notificationId, type);
    }
  }

  /// Handles when a user taps on a notification (background/terminated).
  Future<void> _handleMessageOpened(RemoteMessage message) async {
    final data = message.data;
    final String? notificationId = message.messageId ?? data['notificationId'];
    final String? type = data['type'] ?? 'unknown';
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null && notificationId != null) {
      // Track Click
      await _abService.trackNotificationClicked(userId, notificationId, type);
    }

    // Navigate
    final String? actionType = data['actionType'];
    final String? actionData = data['actionData'];
    // actionId is not available from RemoteMessage usually, unless using action buttons in native payload

    _richNotificationService.handleNavigation(actionType, actionData, null);
  }
}

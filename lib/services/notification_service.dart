import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/notification_ab_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/notification_model.dart';

/// Notification Service - Handles Firebase Cloud Messaging (FCM)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final NotificationABService _abService = NotificationABService();
  final RichNotificationService _richService = RichNotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isInitialized = false;

  /// Initialize Notification Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Background Message Click Handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageOpened(message);
    });

    // Terminated Message Click Handler
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpened(initialMessage);
    }

    // Token Refresh Handler
    _fcm.onTokenRefresh.listen((token) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        saveTokenToDatabase(user.uid);
      }
    });

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Save FCM Token to Firestore
  Future<void> saveTokenToDatabase(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _firestoreService.updateUser(userId, {
          'fcmToken': token,
          'lastTokenUpdate': DateTime.now().toIso8601String(),
        });
        debugPrint('FCM Token saved for user: $userId');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Handle Foreground Message
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground Message Received: ${message.messageId}');

    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Track sending/reception
    if (userId != null) {
      final type = _getNotificationType(message.data['notificationType']);
      _abService.trackNotificationSent(userId, type);
    }

    // Show Rich Notification
    final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().toString(),
      userId: userId ?? '',
      title: title,
      message: body,
      type: message.data['notificationType'] ?? 'system',
      createdAt: DateTime.now(),
      isRead: false,
      imageUrl: message.data['imageUrl'] ?? message.notification?.android?.imageUrl,
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
    );

    _richService.showNotification(notification);
  }

  /// Handle Message Opened (Click)
  void _handleMessageOpened(RemoteMessage message) {
    debugPrint('Message Opened: ${message.messageId}');

    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Track click
    if (userId != null) {
      final type = _getNotificationType(message.data['notificationType']);
      _abService.trackNotificationClicked(userId, type);
    }

    // Navigate
    final actionType = message.data['actionType'];
    final actionData = message.data['actionData'];

    _richService.handleNavigation(actionType, actionData, null);
  }

  /// Helper to map string to NotificationType
  NotificationType _getNotificationType(String? type) {
    if (type == null) return NotificationType.system;

    switch (type.toLowerCase()) {
      case 'match':
      case 'match_success':
        return NotificationType.match;
      case 'message':
        return NotificationType.message;
      case 'event':
        return NotificationType.event;
      case 'rating':
        return NotificationType.rating;
      default:
        return NotificationType.system;
    }
  }
}

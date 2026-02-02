import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'notification_ab_service.dart';
import 'rich_notification_service.dart';
import 'analytics_service.dart';
import '../models/notification_model.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message ${message.messageId}');
  // Background message handling can be implemented here if needed.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationABService _abService = NotificationABService();
  final RichNotificationService _richNotificationService = RichNotificationService();
  final AnalyticsService _analyticsService = AnalyticsService();

  Future<void> initialize() async {
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
      // We can still continue, just notifications won't show
    }

    // Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleRemoteMessage(message);
    });

    // Background/Terminated handler (when opened)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageOpenedApp(message);
    });

    // Check if app was opened from terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    // If no user logged in, use system/default handling or return
    // But we might receive system notifications even if not logged in?
    // AB Test usually requires user ID.
    // We'll fallback to a default ID or skip AB logic if null.
    final effectiveUserId = userId ?? 'guest';

    // Parse data to determine type
    final typeStr = message.data['type'] ?? 'system';
    final type = _getNotificationType(typeStr);

    // Get content based on AB test
    final content = _abService.getContent(
      effectiveUserId,
      type,
      params: message.data,
    );

    final variant = _abService.getGroup(effectiveUserId) == ExperimentGroup.variant ? 'variant' : 'control';

    // Create NotificationModel
    final notificationId = message.messageId ?? const Uuid().v4();

    final notification = NotificationModel(
      id: notificationId,
      userId: effectiveUserId,
      type: typeStr,
      title: content.title,
      message: content.body,
      imageUrl: message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );

    // Log "sent" (received)
    await _analyticsService.logNotificationReceived(
      notificationId: notificationId,
      variant: variant,
    );

    // Display
    // We pass extraPayload to RichNotificationService (will be implemented in next step)
    // For now we assume the method exists or we will add it.
    await _richNotificationService.showNotification(
        notification,
        extraPayload: {'variant': variant}
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
      // Logic for handling click when app opens from background
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
      final variant = _abService.getGroup(userId) == ExperimentGroup.variant ? 'variant' : 'control';

      _analyticsService.logNotificationClicked(
        notificationId: message.messageId ?? 'unknown',
        variant: variant,
      );
  }

  NotificationType _getNotificationType(String type) {
    switch (type) {
      case 'match': return NotificationType.match;
      case 'message': return NotificationType.message;
      case 'event': return NotificationType.event;
      case 'rating': return NotificationType.rating;
      default: return NotificationType.system;
    }
  }
}

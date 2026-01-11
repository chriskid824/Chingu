import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/services/notification_ab_service.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/firebase_options.dart';

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background handling
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('Handling a background message: ${message.messageId}');

  // Note: RichNotificationService might rely on plugins that work in background
  // but we usually let the system handle "notification" payloads automatically.
  // If "data-only", we might need to show it manually if platform allows.
  // For now, we assume standard FCM behavior or simple logging.
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

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (optional here, can be done via requestPermission method)
    // checking current permission status might be good.
    NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User has not granted permission');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    _isInitialized = true;
  }

  /// Request notification permissions
  Future<NotificationSettings> requestPermission() async {
    return await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  /// Get the current FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Delete the current FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  /// Stream of token refreshes
  Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;

  /// Handle messages received while the app is in the foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    // If no user is logged in, we might skip showing personal notifications
    // or show generic ones.

    NotificationModel? notificationModel;

    if (message.notification != null) {
      // Standard notification payload
      notificationModel = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId ?? '',
        type: message.data['type'] ?? 'system',
        title: message.notification!.title ?? '',
        message: message.notification!.body ?? '',
        imageUrl: message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl,
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
        createdAt: DateTime.now(),
      );
    } else if (userId != null) {
      // Data-only payload, use AB Service to generate content
      try {
        final typeStr = message.data['type'] ?? 'system';
        final type = _parseNotificationType(typeStr);

        final content = _abService.getContent(
          userId,
          type,
          params: message.data,
        );

        notificationModel = NotificationModel(
          id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          type: typeStr,
          title: content.title,
          message: content.body,
          imageUrl: message.data['imageUrl'],
          actionType: message.data['actionType'],
          actionData: message.data['actionData'],
          createdAt: DateTime.now(),
        );
      } catch (e) {
        debugPrint('Error processing data-only message: $e');
      }
    }

    if (notificationModel != null) {
      // Check if we should show it (e.g. user settings)
      // We need UserModel for that. Since this is a service, we might need to fetch it
      // or assume the UI/Provider layer handles it.
      // However, RichNotificationService handles the display.
      // We will assume RichNotificationService.showNotification handles the "display" part
      // filtering might happen there if we pass the user model, or here.
      // For now, let's just show it.

      await _richNotificationService.showNotification(notificationModel);
    }
  }

  /// Handle notification tap (User tapped on system notification)
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('A new onMessageOpenedApp event was published!');

    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    _handleNavigation(actionType, actionData);
  }

  /// Navigate based on action type
  void _handleNavigation(String? actionType, String? actionData) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    // Use similar logic to RichNotificationService
    switch (actionType) {
      case 'open_chat':
        if (actionData != null) {
          navigator.pushNamed(AppRoutes.chatList);
        } else {
          navigator.pushNamed(AppRoutes.chatList);
        }
        break;
      case 'view_event':
        // Compatible with existing hardcoded data structure
        navigator.pushNamed(AppRoutes.eventDetail);
        break;
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList);
        break;
      default:
        // Default to notifications screen
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }

  NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'match': return NotificationType.match;
      case 'message': return NotificationType.message;
      case 'event': return NotificationType.event;
      case 'rating': return NotificationType.rating;
      case 'system': default: return NotificationType.system;
    }
  }
}

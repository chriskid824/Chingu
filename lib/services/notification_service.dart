import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions (if not already handled by UI)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      // Convert RemoteMessage to NotificationModel or extract data to show local notification
      _showForegroundNotification(message);
    });

    // Handle Background/Terminated Messages (Tap)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleFCMNavigation);

    _isInitialized = true;
  }

  /// Check for initial message (when app is launched from terminated state)
  /// This should be called after the app is ready (e.g. from MainScreen)
  Future<void> checkForInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleFCMNavigation(initialMessage);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    // Construct NotificationModel from RemoteMessage
    // Note: RemoteMessage.data contains the custom key-values.
    // RemoteMessage.notification contains title/body if sent as notification message.

    // We assume the payload contains enough info to build a NotificationModel
    // or we construct a simple one.

    final data = message.data;
    final notification = message.notification;

    final String title = notification?.title ?? data['title'] ?? 'New Notification';
    final String body = notification?.body ?? data['message'] ?? data['body'] ?? '';

    // We create a temporary NotificationModel to pass to RichNotificationService
    final model = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // Not needed for display
      type: data['type'] ?? 'system',
      title: title,
      message: body,
      imageUrl: data['imageUrl'],
      actionType: data['actionType'] ?? data['type'], // Fallback to type if actionType is missing
      actionData: data['actionData'] ?? data['id'], // Fallback to id if actionData is missing
      createdAt: DateTime.now(),
    );

    RichNotificationService().showNotification(model);
  }

  void _handleFCMNavigation(RemoteMessage message) {
    final data = message.data;
    debugPrint('Handling FCM Navigation: $data');

    final String? actionType = data['actionType'] ?? data['type'];
    final String? actionData = data['actionData'] ?? data['id']; // Commonly used id field
    final String? actionId = data['actionId']; // For buttons

    // Call RichNotificationService to handle navigation
    // Note: We need to ensure RichNotificationService exposes handleNavigation
    RichNotificationService().handleNavigation(actionType, actionData, actionId);
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

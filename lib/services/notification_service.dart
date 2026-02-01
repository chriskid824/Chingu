import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/analytics_service.dart';
import 'package:chingu/services/notification_ab_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AnalyticsService _analytics = AnalyticsService();
  final NotificationABService _abService = NotificationABService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/Terminated -> Opened
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Terminated -> Opened (Initial Message)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');

    await _trackNotification('notification_received', message);

    // Convert to NotificationModel
    final notification = _convertToNotificationModel(message);
    if (notification != null) {
       // Note: Usually A/B testing content generation happens server-side.
       // Here we track the group in analytics.
       // If we needed to dynamically change content based on A/B group locally,
       // we would do it here using _abService.getContent().

       await _richNotificationService.showNotification(notification);
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('Notification opened: ${message.messageId}');
    await _trackNotification('notification_clicked', message);

    // Delegate navigation to RichNotificationService
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];
    final actionId = data['actionId'];

    _richNotificationService.handleNavigation(actionType, actionData, actionId);
  }

  Future<void> _trackNotification(String eventName, RemoteMessage message) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final group = userId != null
        ? _abService.getGroup(userId)
        : ExperimentGroup.control;

    final type = message.data['type'] ?? 'system';

    await _analytics.logEvent(
      name: eventName,
      parameters: {
        'notification_id': message.messageId ?? 'unknown',
        'notification_type': type,
        'experiment_group': group.toString().split('.').last, // 'control' or 'variant'
        'variant': group.toString().split('.').last,
      },
    );
  }

  NotificationModel? _convertToNotificationModel(RemoteMessage message) {
    // If it has notification payload, use it
    String title = message.notification?.title ?? message.data['title'] ?? '';
    String body = message.notification?.body ?? message.data['message'] ?? message.data['body'] ?? '';

    if (title.isEmpty && body.isEmpty) return null;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      type: message.data['type'] ?? 'system',
      title: title,
      message: body,
      imageUrl: message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: message.sentTime ?? DateTime.now(),
    );
  }
}

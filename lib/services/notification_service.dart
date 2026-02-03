import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';
import 'notification_storage_service.dart';
import 'notification_ab_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}

/// Service to handle Firebase Cloud Messaging (FCM) integration and notification tracking.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationStorageService _storageService = NotificationStorageService();
  final RichNotificationService _richNotificationService = RichNotificationService();
  final NotificationABService _abService = NotificationABService();

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      await _processMessage(message, isForeground: true);
    });

    // App opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageInteraction(message);
    });

    // Check if app was opened from terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageInteraction(initialMessage);
    }
  }

  Future<void> _processMessage(RemoteMessage message, {bool isForeground = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('User not logged in, skipping notification processing.');
      return;
    }

    // Convert RemoteMessage to NotificationModel
    final data = message.data;
    final notificationContent = message.notification;

    final String title = notificationContent?.title ?? data['title'] ?? 'New Notification';
    final String body = notificationContent?.body ?? data['body'] ?? data['message'] ?? '';
    final String type = data['type'] ?? 'system';

    // Construct model
    final String id = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final notification = NotificationModel(
      id: id,
      userId: user.uid,
      type: type,
      title: title,
      message: body,
      imageUrl: data['imageUrl'],
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: message.sentTime ?? DateTime.now(),
      isRead: false,
    );

    // Track 'received' event
    await _abService.trackNotificationEvent(
      userId: user.uid,
      notificationType: type,
      eventType: 'received',
    );

    // Save to storage
    try {
        await _storageService.saveNotification(notification);
    } catch (e) {
        debugPrint('Error saving notification: $e');
    }

    // Show local notification if in foreground (and if we want to show it)
    if (isForeground) {
      await _richNotificationService.showNotification(notification);
    }
  }

  void _handleMessageInteraction(RemoteMessage message) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
       final type = message.data['type'] ?? 'system';
       _abService.trackNotificationEvent(
        userId: user.uid,
        notificationType: type,
        eventType: 'clicked',
      );
    }

    final actionType = message.data['actionType'];
    final actionData = message.data['actionData'];
    // actionId is null for general tap
    _richNotificationService.handleNavigation(actionType, actionData, null);
  }
}

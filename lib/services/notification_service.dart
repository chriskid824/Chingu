import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      final notificationModel = _mapRemoteMessageToNotificationModel(message);
      RichNotificationService().showNotification(notificationModel);
    });

    // Background (opened app) message handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageNavigation(message);
    });
  }

  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      _handleMessageNavigation(initialMessage);
    }
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'] as String?;
    final actionData = data['actionData'] as String?;
    final actionId = data['actionId'] as String?;

    RichNotificationService().handleNavigation(actionType, actionData, actionId);
  }

  NotificationModel _mapRemoteMessageToNotificationModel(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? '',
      message: notification?.body ?? data['message'] ?? '',
      imageUrl: data['imageUrl'] ?? notification?.android?.imageUrl,
      actionType: data['actionType'],
      actionData: data['actionData'],
      isRead: false,
      createdAt: message.sentTime ?? DateTime.now(),
    );
  }
}

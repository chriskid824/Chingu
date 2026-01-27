import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  Future<Map<String, dynamic>?> initialize() async {
    if (_isInitialized) return null;

    // Request permission
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

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        // Construct NotificationModel
        final notification = NotificationModel(
          id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          type: message.data['type'] ?? 'system',
          title: message.notification?.title ?? '',
          message: message.notification?.body ?? '',
          imageUrl: message.data['imageUrl'] ?? (message.notification?.android?.imageUrl),
          actionType: message.data['actionType'],
          actionData: message.data['actionData'],
          createdAt: message.sentTime ?? DateTime.now(),
        );

        // Show local notification using RichNotificationService
        RichNotificationService().showNotification(notification);
      }
    });

    // Background message interaction (App opened from background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleRemoteNavigation(message);
    });

    // Terminated state interaction (App opened from terminated)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    _isInitialized = true;

    if (initialMessage != null) {
      debugPrint('App opened from terminated state via notification');
      return {
        'actionType': initialMessage.data['actionType'],
        'actionData': initialMessage.data['actionData'],
      };
    }

    return null;
  }

  void _handleRemoteNavigation(RemoteMessage message) {
    final actionType = message.data['actionType'];
    final actionData = message.data['actionData'];

    // Delegate to RichNotificationService
    RichNotificationService().handleNavigation(actionType, actionData, null);
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

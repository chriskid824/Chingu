import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'in_app_notification_service.dart';
import '../core/routes/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        final notification = _createNotificationModel(message);
        InAppNotificationService().show(notification);
      }
    });

    // Message opened app handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleNavigation(message);
    });

    // Check initial message (if app was terminated)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage);
    }
  }

  NotificationModel _createNotificationModel(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().toString(),
      userId: '', // Not strictly needed for display
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? 'Notification',
      message: message.notification?.body ?? '',
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );
  }

  void _handleNavigation(RemoteMessage message) {
    final actionType = message.data['actionType'];
    // final actionData = message.data['actionData']; // unused for now
    final navigator = AppRouter.navigatorKey.currentState;

    if (navigator == null) return;

    switch (actionType) {
      case 'open_chat':
        navigator.pushNamed(AppRoutes.chatList);
        break;
      case 'view_event':
        navigator.pushNamed(AppRoutes.eventDetail);
        break;
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList);
        break;
      default:
        navigator.pushNamed(AppRoutes.notifications);
    }
  }
}

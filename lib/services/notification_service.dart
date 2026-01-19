import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';
import '../core/routes/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint("Handling a background message: ${message.messageId}");

  if (message.notification == null) {
    // Data only message: manually show notification
    final notification = _createNotificationModelFromMessage(message);
    if (notification != null) {
      final richNotificationService = RichNotificationService();
      await richNotificationService.initialize();
      await richNotificationService.showNotification(notification);
    }
  }
}

NotificationModel? _createNotificationModelFromMessage(RemoteMessage message) {
  final data = message.data;
  if (data.isEmpty && message.notification == null) return null;

  return NotificationModel(
    id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    userId: data['userId'] ?? '',
    type: data['type'] ?? 'system',
    title: data['title'] ?? (message.notification?.title ?? 'Notification'),
    message: data['body'] ?? (message.notification?.body ?? ''),
    imageUrl: data['imageUrl'],
    actionType: data['actionType'],
    actionData: data['actionData'],
    createdAt: DateTime.now(),
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      // If notification payload exists, Firebase might not show it in foreground.
      // We choose to always show local notification for consistency and rich features.
      final notification = _createNotificationModelFromMessage(message);
      if (notification != null) {
        RichNotificationService().showNotification(notification);
      }
    });

    // Background/Terminated -> Opened handler (Stream)
    // This handles cases where the user taps on a System Notification (if sent)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleRemoteMessageNavigation(message);
    });
  }

  /// Get initial FCM data for app launch
  Future<Map<String, dynamic>?> getInitialFCMData() async {
    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      return _getRouteInfoFromMessage(initialMessage);
    }
    return null;
  }

  void _handleRemoteMessageNavigation(RemoteMessage message) {
    final routeInfo = _getRouteInfoFromMessage(message);
    if (routeInfo != null) {
      final navigator = AppRouter.navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamed(
          routeInfo['route'],
          arguments: routeInfo['arguments'],
        );
      }
    }
  }

  Map<String, dynamic>? _getRouteInfoFromMessage(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];
    // final actionData = data['actionData'];

    String? route;
    Object? arguments;

    switch (actionType) {
      case 'open_chat':
        route = AppRoutes.chatList;
        break;
      case 'view_event':
        route = AppRoutes.eventDetail;
        break;
      case 'match_history':
        route = AppRoutes.matchesList;
        break;
      default:
        if (actionType != null) {
          route = AppRoutes.notifications;
        }
        break;
    }

    if (route != null) {
      return {'route': route, 'arguments': arguments};
    }
    return null;
  }
}

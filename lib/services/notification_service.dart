import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';
import '../services/rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  void initialize() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification == null) return;

    // Convert RemoteMessage to NotificationModel
    // Note: userId is current user, but for display it's not strictly needed.
    // However, NotificationModel requires it.
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUserId,
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? '',
      message: message.notification?.body ?? '',
      imageUrl: message.notification?.android?.imageUrl ?? message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      isRead: false,
      createdAt: DateTime.now(),
    );

    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      InAppNotification.show(
        context,
        notification,
        onTap: () {
            // Use RichNotificationService's logic to handle navigation
            // We can reuse the logic by calling a helper or similar,
            // but RichNotificationService is for Local Notifications.
            // We should replicate the navigation logic here or expose it.
            // Since RichNotificationService has `_handleNavigation` as private,
            // we will implement simple navigation here matching what we saw in RichNotificationService.
            _handleNavigation(notification);
        },
      );
    }
  }

  void _handleNavigation(NotificationModel notification) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final actionType = notification.actionType;
    final actionData = notification.actionData;

    switch (actionType) {
      case 'open_chat':
        navigator.pushNamed(AppRoutes.chatList);
        break;
      case 'view_event':
        navigator.pushNamed(AppRoutes.eventDetail); // Ideally pass arguments if supported
        break;
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList);
        break;
      default:
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }
}

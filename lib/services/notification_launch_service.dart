import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../core/routes/app_router.dart';

class LaunchContext {
  final String route;
  final Object? arguments;

  LaunchContext({required this.route, this.arguments});
}

class NotificationLaunchService {
  static final NotificationLaunchService _instance = NotificationLaunchService._internal();

  factory NotificationLaunchService() {
    return _instance;
  }

  NotificationLaunchService._internal();

  /// Checks for the notification that launched the app (if any)
  /// and returns the initial route and arguments.
  Future<LaunchContext> getInitialLaunchContext() async {
    // 1. Check for remote notification launch (FCM)
    try {
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App launched from FCM notification: ${initialMessage.data}');
        return _parseNotificationData(initialMessage.data);
      }
    } catch (e) {
      debugPrint('Error checking FCM initial message: $e');
    }

    // 2. Check for local notification launch
    try {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      final NotificationAppLaunchDetails? notificationAppLaunchDetails =
          await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        final payload = notificationAppLaunchDetails?.notificationResponse?.payload;
        if (payload != null) {
          debugPrint('App launched from Local notification: $payload');
          return _parseLocalNotificationPayload(payload);
        }
      }
    } catch (e) {
      debugPrint('Error checking local notification launch details: $e');
    }

    return LaunchContext(route: AppRoutes.mainNavigation);
  }

  LaunchContext _parseNotificationData(Map<String, dynamic> data) {
    final String? actionType = data['actionType'];
    // Parsing actionData. It might be a JSON string or a direct value depending on sender
    // RichNotificationService puts JSON encoded map sometimes, or just string.
    // We will assume it's a string that might need decoding or usage as is.
    final dynamic actionData = data['actionData'];

    if (actionType != null) {
      return _getLaunchContextFromAction(actionType, actionData);
    }

    return LaunchContext(route: AppRoutes.mainNavigation);
  }

  LaunchContext _parseLocalNotificationPayload(String payload) {
    try {
      final Map<String, dynamic> data = json.decode(payload);
      final String? actionType = data['actionType'];
      final dynamic actionData = data['actionData'];

      if (actionType != null) {
        return _getLaunchContextFromAction(actionType, actionData);
      }
    } catch (e) {
      debugPrint('Error parsing launch payload: $e');
    }
    return LaunchContext(route: AppRoutes.mainNavigation);
  }

  LaunchContext _getLaunchContextFromAction(String actionType, dynamic actionData) {
    switch (actionType) {
      case 'open_chat':
        // ChatDetailScreen expects arguments: Map<String, dynamic> { 'chatRoomId': ..., 'otherUser': ... }
        // If actionData is just chatRoomId or userId, we might not have full info.
        // If we only have chatRoomId, we can't fully populate ChatDetailScreen without fetching user.
        // However, we can try to pass what we have.
        // Assuming actionData is the chatRoomId string for now, or a JSON map.

        if (actionData is String) {
          // If it looks like a JSON map
          if (actionData.startsWith('{') && actionData.endsWith('}')) {
             try {
                final Map<String, dynamic> map = json.decode(actionData);
                return LaunchContext(route: AppRoutes.chatDetail, arguments: map);
             } catch (_) {
                // Not json, maybe just ID.
             }
          }
          // If just ID, we might need to fetch data or route to chat list
           return LaunchContext(route: AppRoutes.chatList);
        } else if (actionData is Map<String, dynamic>) {
           return LaunchContext(route: AppRoutes.chatDetail, arguments: actionData);
        }

        return LaunchContext(route: AppRoutes.chatList);

      case 'view_event':
        // EventDetailScreen arguments?
        // Based on routes code: case AppRoutes.eventDetail: return MaterialPageRoute(builder: (_) => const EventDetailScreen());
        // It doesn't seem to take arguments in the route generator (it's const).
        // It might use a Provider to get the selected event.
        // So simply navigating there might be enough if the provider state is set?
        // But initializing from cold start, provider is empty.
        // If EventDetailScreen relies on `DinnerEventProvider.selectedEvent`, we can't easily set it from here without access to Provider container.

        // Strategy: Navigate to Events List instead if we can't set state, or rely on deep linking handling inside the screen if it checks arguments (which it doesn't seem to do in route gen).
        return LaunchContext(route: AppRoutes.eventDetail);

      case 'match_history':
        return LaunchContext(route: AppRoutes.matchesList);

      default:
        return LaunchContext(route: AppRoutes.notifications);
    }
  }
}

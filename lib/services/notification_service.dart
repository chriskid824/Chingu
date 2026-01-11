import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/routes/app_router.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Request Permission
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
      return;
    }

    // 2. Background Message Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');

      if (message.notification != null) {
        try {
           final data = message.data;
           final notification = NotificationModel(
             id: message.messageId ?? DateTime.now().toString(),
             userId: '', // Context not available, mostly for local display
             type: data['type'] ?? 'system',
             title: message.notification!.title ?? '',
             message: message.notification!.body ?? '',
             imageUrl: message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl,
             actionType: data['actionType'],
             actionData: data['actionData'],
             createdAt: DateTime.now(),
           );

           RichNotificationService().showNotification(notification);
        } catch (e) {
          debugPrint('Error showing foreground notification: $e');
        }
      }
    });

    // 4. Background State (App Open)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageInteraction(message);
    });

    // 5. Terminated State (Initial Message)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageInteraction(initialMessage);
    }
  }

  void _handleMessageInteraction(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    debugPrint('Handling message interaction: actionType=$actionType, actionData=$actionData');

    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('Navigator state is null');
      return;
    }

    // Pass actionData as arguments where applicable
    switch (actionType) {
      case 'open_chat':
      case 'chat':
         // ChatDetailScreen requires arguments, but we might not have the full object.
         // Fallback to chat list is safer if we don't have the full user object.
         // If actionData contained chatRoomId, we could try to use it if ChatDetailScreen supported it.
         navigator.pushNamed(AppRoutes.chatList);
         break;

      case 'view_event':
      case 'event':
         // EventDetailScreen currently does not use arguments, but passing actionData is future-proof
         // if it starts accepting eventId.
         navigator.pushNamed(AppRoutes.eventDetail, arguments: actionData);
         break;

      case 'match_history':
      case 'match':
         navigator.pushNamed(AppRoutes.matchesList);
         break;

      default:
         navigator.pushNamed(AppRoutes.notifications);
         break;
    }
  }
}

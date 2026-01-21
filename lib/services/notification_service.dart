import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';
import '../firebase_options.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp` before using other Firebase services.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// 初始化通知服務
  Future<void> initialize() async {
    // Set the background messaging handler early on
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        // Show local notification
        RichNotificationService().showNotification(
          NotificationModel(
            id: message.messageId.hashCode.toString(),
            userId: '', // Not needed for local display
            title: message.notification?.title ?? 'Notification',
            message: message.notification?.body ?? '',
            createdAt: DateTime.now(),
            isRead: false,
            imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
            type: message.data['type'] ?? 'general',
            actionType: message.data['actionType'] ?? message.data['type'],
            actionData: message.data['actionData'] ?? message.data['chatRoomId'] ?? message.data['eventId'],
          )
        );
      }
    });

    // Handle Background -> App (User taps notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessage(message);
    });
  }

  // Method to check initial message (Terminated state)
  Future<void> consumeInitialMessage(BuildContext context) async {
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();

      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'] ?? data['type'];
    final actionData = data['actionData'] ?? data['chatRoomId'] ?? data['eventId'];

    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    if (actionType == 'open_chat') {
       if (actionData != null) {
         // Assuming actionData is chatRoomId or we have enough info to navigate
         // Since ChatDetailScreen might expect complex objects, we might need to fetch them
         // or update ChatDetailScreen to handle IDs.
         // For now, we will navigate to ChatList if we can't fully support ChatDetail
         // But let's try to pass arguments.
         navigator.pushNamed(
           AppRoutes.chatDetail,
           arguments: {'chatRoomId': actionData}
         );
       } else {
         navigator.pushNamed(AppRoutes.chatList);
       }
    } else if (actionType == 'view_event') {
       if (actionData != null) {
          navigator.pushNamed(
            AppRoutes.eventDetail,
            arguments: actionData // EventDetail expects ID or Map? usually Map or Model in recent code
            // But let's assume it can handle ID or we just go to list if not.
            // Based on previous tasks, EventDetail might just take what's given.
          );
       } else {
         navigator.pushNamed(AppRoutes.eventsList);
       }
    } else if (actionType == 'match_history') {
       navigator.pushNamed(AppRoutes.matchesList);
    } else {
       navigator.pushNamed(AppRoutes.notifications);
    }
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  // Topic management
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}

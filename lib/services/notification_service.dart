import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/routes/app_router.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';
import '../firebase_options.dart';
import 'firestore_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  RemoteMessage? _initialMessage;
  bool _isInitialized = false;

  /// 初始化通知服務 (設定監聽器，不請求權限)
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Get Initial Message (Terminated state)
    try {
      _initialMessage = await _firebaseMessaging.getInitialMessage();
    } catch (e) {
      debugPrint('Error getting initial message: $e');
    }

    // 3. Handle Background State (App Open from Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message);
    });

    // 4. Handle Foreground State
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        final notification = NotificationModel(
          id: message.messageId ?? DateTime.now().toString(),
          userId: message.data['userId'] ?? '',
          type: message.data['type'] ?? 'system',
          title: message.notification?.title ?? '',
          message: message.notification?.body ?? '',
          imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
          actionType: message.data['actionType'],
          actionData: message.data['actionData'],
          isRead: false,
          createdAt: DateTime.now(),
        );

        RichNotificationService().showNotification(notification);
      }
    });

    _isInitialized = true;
  }

  /// 請求通知權限
  Future<void> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  bool get hasInitialMessage => _initialMessage != null;

  bool consumeInitialMessage(BuildContext context) {
    if (_initialMessage != null) {
      _handleNavigation(_initialMessage!, context: context);
      _initialMessage = null;
      return true;
    }
    return false;
  }

  /// 獲取並更新 FCM Token
  Future<void> updateFCMToken(String userId) async {
    try {
      // 獲取當前 Token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirestoreService().updateUser(userId, {'fcmToken': token});
        debugPrint('FCM Token updated: $token');
      }

      // 監聽 Token 刷新
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        await FirestoreService().updateUser(userId, {'fcmToken': newToken});
        debugPrint('FCM Token refreshed: $newToken');
      });
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  void _handleNavigation(RemoteMessage message, {BuildContext? context}) {
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    final navigator = context != null ? Navigator.of(context) : AppRouter.navigatorKey.currentState;

    if (navigator == null) return;

    switch (actionType) {
      case 'open_chat':
         navigator.pushNamed(AppRoutes.chatList, arguments: actionData);
         break;
      case 'view_event':
         navigator.pushNamed(AppRoutes.eventDetail, arguments: actionData);
         break;
      case 'match_history':
         navigator.pushNamed(AppRoutes.matchesList, arguments: actionData);
         break;
      default:
         navigator.pushNamed(AppRoutes.notifications);
    }
  }
}

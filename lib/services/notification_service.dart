import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'rich_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 處理背景訊息
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 處理 App 在背景被點擊開啟
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // 請求通知權限
    NotificationSettings settings = await _messaging.requestPermission(
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
  }

  /// 處理 App 在終止狀態被點擊開啟的邏輯
  /// 應在 UI 初始化完成後調用（如 MainScreen 的 initState）
  Future<void> setupInteractedMessage() async {
    // 處理 App 在終止狀態被點擊開啟
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final String? actionType = data['actionType'];
    final String? actionData = data['actionData'];

    // 使用 RichNotificationService 處理導航
    RichNotificationService().handleNavigation(actionType, actionData, null);
  }
}

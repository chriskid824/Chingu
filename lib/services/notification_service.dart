import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
    // 註冊後台消息處理器
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 處理前景消息
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      final notificationModel = _remoteMessageToModel(message);
      RichNotificationService().showNotification(notificationModel);
    });

    // 處理後台開啟 App (onMessageOpenedApp)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageInteraction(message);
    });
  }

  /// 請求通知權限
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

  /// 檢查是否從通知啟動 App
  Future<void> checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state via notification');
      _handleMessageInteraction(initialMessage);
    }
  }

  /// 處理消息互動 (導航)
  void _handleMessageInteraction(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];
    // actionId 在 FCM payload 中通常不在 data 裡，這裡主要處理點擊通知本體
    RichNotificationService().handleNavigation(actionType, actionData, null);
  }

  /// 將 RemoteMessage 轉換為 NotificationModel
  NotificationModel _remoteMessageToModel(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: data['userId'] ?? '', // 這裡可能需要根據實際情況獲取
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? '收到新通知',
      message: notification?.body ?? data['message'] ?? '',
      imageUrl: notification?.android?.imageUrl ??
                notification?.apple?.imageUrl ??
                data['imageUrl'],
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: message.sentTime ?? DateTime.now(),
    );
  }

  /// 獲取 FCM Token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

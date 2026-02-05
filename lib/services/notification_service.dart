import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp` before using other Firebase services.
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

  // 暫存初始訊息，等待 UI 準備就緒後處理
  RemoteMessage? _initialMessage;

  Future<void> initialize() async {
    // 請求權限
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

    // 背景訊息處理
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 前景訊息監聽
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // 背景點擊通知 (App 在背景)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageOpenedApp(message);
    });

    // 終止狀態點擊通知 (App 未啟動)
    // 這裡只獲取，不立即處理，因為 Navigator 可能還沒準備好
    _initialMessage = await _firebaseMessaging.getInitialMessage();

    // 獲取並打印 FCM Token (方便調試)
    String? token = await _firebaseMessaging.getToken();
    debugPrint("FCM Token: $token");
  }

  /// 處理初始訊息 (應在 UI/Navigator 準備就緒後調用，例如 MainScreen)
  void handleInitialMessage() {
    if (_initialMessage != null) {
      _handleMessageOpenedApp(_initialMessage!);
      _initialMessage = null;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');

      // 轉換並顯示本地通知
      final notification = _mapToNotificationModel(message);
      RichNotificationService().showNotification(notification);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('A new onMessageOpenedApp event was published!');
    final data = message.data;

    // 提取 actionType 和 actionData
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    RichNotificationService().handleNavigation(actionType, actionData, null);
  }

  NotificationModel _mapToNotificationModel(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // 前端展示不需要 userId
      type: data['type'] ?? 'system',
      title: notification?.title ?? '',
      message: notification?.body ?? '',
      imageUrl: notification?.android?.imageUrl ?? notification?.apple?.imageUrl,
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: message.sentTime ?? DateTime.now(),
      isRead: false,
    );
  }
}

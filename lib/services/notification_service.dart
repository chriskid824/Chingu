import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'in_app_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  /// 初始化通知服務 (FCM)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 請求權限
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }

      // 監聽前台訊息
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 取得初始訊息 (如果 App 是從終止狀態被通知開啟)
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        // 這裡可以處理點擊通知後的導航，但通常由 RichNotificationService 或 AppRouter 處理
        debugPrint('App opened from terminated state via notification: ${initialMessage.messageId}');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
    }

    // 轉換並顯示 In-App Notification
    final notification = _messageToNotificationModel(message);
    InAppNotificationService().show(notification);
  }

  NotificationModel _messageToNotificationModel(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    // 嘗試從 data 或 notification 中提取資訊
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // 用於顯示時不需要 userId
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? '新通知',
      message: notification?.body ?? data['body'] ?? data['message'] ?? '',
      imageUrl: data['imageUrl'] ?? data['image'],
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: DateTime.now(),
      isRead: false,
    );
  }
}

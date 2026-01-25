import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 請求權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 監聽前景訊息
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 監聽背景開啟 App 的訊息
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 檢查 App 是否是從終止狀態開啟
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    _isInitialized = true;
  }

  /// 處理前景訊息
  void _handleForegroundMessage(RemoteMessage message) {
    // 即使在前景，如果沒有 notification 內容，可能只是數據訊息，這裡假設都需要顯示
    // 但通常 InAppNotification 用於顯示可視內容
    if (message.notification != null || message.data.isNotEmpty) {
      final notification = _createNotificationModel(message);

      // 顯示應用內橫幅
      InAppNotification.show(
        notification,
        onTap: () => _handleTap(notification),
      );
    }
  }

  /// 處理從通知開啟 App
  void _handleMessageOpenedApp(RemoteMessage message) {
    final notification = _createNotificationModel(message);
    _handleTap(notification);
  }

  /// 將 RemoteMessage 轉換為 NotificationModel
  NotificationModel _createNotificationModel(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? 'Notification',
      message: notification?.body ?? data['message'] ?? '',
      imageUrl: data['imageUrl'] ?? (notification?.android?.imageUrl ?? notification?.apple?.imageUrl),
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: message.sentTime ?? DateTime.now(),
    );
  }

  /// 處理通知點擊導航
  void _handleTap(NotificationModel notification) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    switch (notification.actionType) {
      case 'open_chat':
        navigator.pushNamed(AppRoutes.chatList);
        break;
      case 'view_event':
        navigator.pushNamed(AppRoutes.eventDetail);
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

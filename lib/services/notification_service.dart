import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';

/// 處理背景消息的回調函數
/// 必須是頂層函數
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  // 如果需要處理數據消息的本地存儲等邏輯，可以在這裡實現
  // 注意：這裡無法訪問 Provider 或 UI 上下文
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. 請求權限
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

    // 2. 獲取 Token (用於測試/調試)
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint("FCM Token: $token");
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }

    // 3. 設置背景消息處理器
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. 處理前台消息
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      // 將 RemoteMessage 轉換為 NotificationModel 並顯示本地通知
      final notificationModel = _mapRemoteMessageToModel(message);
      RichNotificationService().showNotification(notificationModel);
    });

    // 5. 處理後台應用打開 (App in background -> opened)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageAction(message);
    });

    // 6. 處理終止狀態打開 (App terminated -> opened)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state via notification');
      _handleMessageAction(initialMessage);
    }

    _isInitialized = true;
  }

  /// 處理通知點擊後的動作
  void _handleMessageAction(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    // 調用 RichNotificationService 的導航邏輯
    RichNotificationService().handleNotificationAction(actionType, actionData, null);
  }

  /// 將 RemoteMessage 轉換為 NotificationModel
  NotificationModel _mapRemoteMessageToModel(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      // 這裡如果無法獲取當前用戶 ID，暫時使用空字符串，因為本地顯示不需要它存入數據庫
      // 如果需要在這裡存入數據庫，則需要確保 Auth 已初始化
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? '收到新通知',
      message: notification?.body ?? data['message'] ?? '',
      imageUrl: notification?.android?.imageUrl ?? data['imageUrl'],
      actionType: data['actionType'],
      actionData: data['actionData'],
      isRead: false,
      createdAt: message.sentTime ?? DateTime.now(),
    );
  }
}

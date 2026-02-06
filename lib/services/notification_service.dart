import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_storage_service.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';

/// 通知服務
/// 負責處理 FCM 權限、Token、接收消息並分發給 StorageService 和 RichNotificationService
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationStorageService _storageService = NotificationStorageService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. 請求權限
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 2. 獲取 Token
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // 3. 監聽前景消息
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 4. 監聽後台應用打開消息
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    _isInitialized = true;
  }

  /// 處理前景消息
  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Got a message whilst in the foreground!');

    // 轉換為 NotificationModel
    final notification = _convertToNotificationModel(message);

    // 1. 儲存到 Firestore (如果用戶已登入)
    // 即使是用戶自己觸發的通知（理論上不應該發送給自己），這裡也會收到並儲存
    if (FirebaseAuth.instance.currentUser != null) {
        try {
            await _storageService.saveNotification(notification);
        } catch (e) {
            debugPrint('Error saving notification: $e');
        }
    }

    // 2. 顯示本地通知
    _richNotificationService.showNotification(notification);
  }

  /// 處理從後台打開的消息
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message clicked!');
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];
    _richNotificationService.handleNavigation(actionType, actionData, null);
  }

  /// 將 RemoteMessage 轉換為 NotificationModel
  NotificationModel _convertToNotificationModel(RemoteMessage message) {
    // 嘗試從 data 中獲取，如果沒有則使用 notification 對象
    final data = message.data;
    final notification = message.notification;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // 優先使用 data 中的字段，因為它們更靈活
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? 'Notification',
      message: notification?.body ?? data['body'] ?? data['message'] ?? '',
      imageUrl: data['imageUrl'] ?? data['image'],
      actionType: data['actionType'],
      actionData: data['actionData'],
      isRead: false,
      createdAt: DateTime.now(),
    );
  }
}

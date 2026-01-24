import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 請求權限
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 監聽前景消息
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    _isInitialized = true;
  }

  /// 處理前景消息
  void _onForegroundMessage(RemoteMessage message) {
    try {
      final notificationModel = _mapToNotificationModel(message);
      // 確保有內容才顯示
      if (notificationModel.title.isNotEmpty || notificationModel.message.isNotEmpty) {
        InAppNotification.show(notificationModel);
      }
    } catch (e) {
      debugPrint('Error showing in-app notification: $e');
    }
  }

  /// 將 RemoteMessage 轉換為 NotificationModel
  NotificationModel _mapToNotificationModel(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? '',
      message: notification?.body ?? data['message'] ?? '',
      imageUrl: data['imageUrl'] ?? (notification?.android?.imageUrl ?? notification?.apple?.imageUrl),
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: DateTime.now(),
      isRead: false,
    );
  }
}

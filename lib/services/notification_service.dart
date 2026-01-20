import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/firestore_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// 初始化通知服務
  Future<void> initialize() async {
    // 請求權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 獲取並打印 Token (調試用)
    String? token = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');

    // 處理 App 關閉狀態下點擊通知開啟 App
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleMessage(message);
      }
    });

    // 處理 App 在背景狀態下點擊通知
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // 處理 App 在前景接收通知
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        final data = message.data;

        // 構建 NotificationModel 用於顯示本地通知
        final notification = NotificationModel(
           id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
           userId: '', // 本地顯示不需要
           type: data['type'] ?? 'system',
           title: message.notification?.title ?? data['title'] ?? '通知',
           message: message.notification?.body ?? data['message'] ?? '',
           imageUrl: data['imageUrl'] ?? (message.notification?.android?.imageUrl),
           actionType: data['actionType'],
           actionData: data['actionData'],
           createdAt: DateTime.now(),
        );

        RichNotificationService().showNotification(notification);
      }
    });
  }

  /// 處理通知點擊跳轉
  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    // 委託給 RichNotificationService 處理導航，確保邏輯一致
    // 注意：需要確保 RichNotificationService 有公開的 handleNavigation 方法
    RichNotificationService().handleNavigation(actionType, actionData, null);
  }

  /// 更新用戶 FCM Token
  Future<void> updateUserToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirestoreService().updateUser(userId, {'fcmToken': token});
        debugPrint('Updated FCM token for user $userId');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// 檢查是否有初始消息 (用於 Cold Start 導航)
  /// 如果 main.dart 或 MainScreen 需要手動觸發
  Future<void> checkForInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }
}

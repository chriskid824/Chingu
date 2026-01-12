import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  // 可以在這裡處理後台消息，例如資料同步
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  Future<void> initialize() async {
    // 請求權限
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

    // 設置後台處理程序
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 前台消息監聽
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('收到前台消息: ${message.messageId}');

      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // 處理打開應用時的消息交互
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
       debugPrint('應用從後台被打開，消息 ID: ${message.messageId}');
       // 這裡可以導航，RichNotificationService 應該已經處理了點擊本地通知的邏輯
       // 但如果點擊的是系統托盤中的 FCM 通知（當應用在後台時），系統會直接打開應用
       // 我們可能需要處理路由跳轉
       _handleNotificationTap(message);
    });
  }

  /// 獲取並更新 Token
  Future<void> updateTokenForUser(String uid) async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint("FCM Token: $token");
      await _firestoreService.updateFcmToken(uid, token);
    }

    _firebaseMessaging.onTokenRefresh.listen((String newToken) {
      debugPrint("FCM Token Refreshed: $newToken");
      _firestoreService.updateFcmToken(uid, newToken);
    });
  }

  void _showLocalNotification(RemoteMessage message) {
     final notification = message.notification;
     final data = message.data;

     if (notification == null) return;

     final model = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // 這裡不需要 userId，因為是本地顯示
        type: data['type'] ?? 'system',
        title: notification.title ?? '',
        message: notification.body ?? '',
        imageUrl: data['imageUrl'] ?? (notification.android?.imageUrl),
        actionType: data['actionType'],
        actionData: data['actionData'],
        createdAt: DateTime.now(),
     );

     _richNotificationService.showNotification(model);
  }

  void _handleNotificationTap(RemoteMessage message) {
    // 簡單委派給 RichNotificationService 的邏輯（如果它可以公開該邏輯）
    // 或者重寫導航邏輯。由於 RichNotificationService 有 _handleNavigation 但它是私有的。
    // 這裡我們簡單構建一個 NotificationModel 並再次觸發 "點擊" 邏輯可能比較複雜。
    // 但通常 onMessageOpenedApp 發生時，用戶點擊了系統通知。
    // 我們可以解析 data 並導航。

    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    // 這裡需要 Context 才能導航。RichNotificationService 使用 AppRouter.navigatorKey
    // 我們可以嘗試調用 RichNotificationService 的公開方法，如果有的話。
    // 目前沒有公開方法處理這個。我們可以在這裡實現類似的邏輯。

    /*
       注意：由於 RichNotificationService 已經處理了 Local Notification 的點擊，
       onMessageOpenedApp 主要處理的是：當應用在後台，FCM SDK 顯示通知（如果 notification 字段存在），
       用戶點擊該通知打開應用。
    */
  }
}

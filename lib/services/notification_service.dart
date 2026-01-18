import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/services/notification_ab_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:flutter/foundation.dart';

/// 通知服務
///
/// 負責初始化 FCM，處理前台、後台通知接收與點擊，
/// 並整合 A/B 測試與統計追蹤。
class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final RichNotificationService _richNotificationService = RichNotificationService();
  final NotificationABService _notificationABService = NotificationABService();

  bool _isInitialized = false;

  /// 初始化通知服務
  ///
  /// [currentUserId] 當前登入用戶 ID，用於 A/B 分組與統計
  Future<void> initialize(String currentUserId) async {
    if (_isInitialized) return;

    // 1. 初始化本地通知顯示服務 (RichNotificationService)
    await _richNotificationService.initialize();

    // 2. 請求 FCM 權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      // 可以在這裡處理權限拒絕的邏輯，例如提示用戶
    }

    // 3. 獲取 FCM Token (可選，通常在 AuthProvider 或登入後處理)
    // String? token = await _firebaseMessaging.getToken();
    // debugPrint("FCM Token: $token");

    // 4. 設定前台訊息監聽
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message, currentUserId);
    });

    // 5. 設定後台點擊監聽 (App 從後台被喚起)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageOpenedApp(message, currentUserId);
    });

    // 6. 檢查是否從 Terminated 狀態被喚起
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage, currentUserId);
    }

    _isInitialized = true;
  }

  /// 處理前台收到的訊息
  void _handleForegroundMessage(RemoteMessage message, String currentUserId) async {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
    }

    // 根據訊息類型決定是否顯示本地通知，以及使用 A/B 測試內容
    // 假設 RemoteMessage data 包含 type
    final typeStr = message.data['type'] as String? ?? 'system';
    final notificationType = _parseNotificationType(typeStr);

    // 獲取 A/B 測試內容 (如果 RemoteMessage payload 沒帶 title/body，則由客戶端生成)
    // 如果 RemoteMessage 已經有 notification 屬性，通常直接顯示
    // 這裡示範如何結合 ABService 生成或替換內容

    NotificationContent content;
    // 如果後端發送的是 data-only message，則完全由客戶端決定顯示內容
    if (message.notification == null) {
       content = _notificationABService.getContent(
        currentUserId,
        notificationType,
        params: message.data,
      );
    } else {
      // 如果有 notification payload，則直接使用，或者根據 A/B 測試微調
      // 這裡簡單起見，如果有 payload 就用 payload，否則用 ABService
      content = NotificationContent(
        title: message.notification!.title ?? '',
        body: message.notification!.body ?? '',
      );
    }

    // 追蹤發送 (Received in foreground)
    await _notificationABService.trackNotificationSent(
      userId: currentUserId,
      type: notificationType,
      notificationId: message.messageId,
    );

    // 顯示本地通知
    // 構造 NotificationModel
    final notificationModel = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: content.title,
      message: content.body,
      timestamp: DateTime.now(),
      isRead: false,
      type: typeStr,
      imageUrl: message.data['imageUrl'], // 假設 payload 有 imageUrl
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
    );

    // 為了讓點擊本地通知也能追蹤，我們需要在 actionData 中夾帶一些 meta info
    // 或者 RichNotificationService 點擊回調時，我們能知道這是哪個 notification
    // RichNotificationService 的 payload 包含 notificationId

    await _richNotificationService.showNotification(notificationModel);
  }

  /// 處理通知被點擊 (Background / Terminated -> Opened)
  void _handleMessageOpenedApp(RemoteMessage message, String currentUserId) {
    debugPrint('A new onMessageOpenedApp event was published!');

    final typeStr = message.data['type'] as String? ?? 'system';
    final notificationType = _parseNotificationType(typeStr);

    // 追蹤點擊
    _notificationABService.trackNotificationClicked(
      userId: currentUserId,
      type: notificationType,
      notificationId: message.messageId,
    );

    // 導航邏輯通常由 RichNotificationService 的邏輯處理，或者在這裡直接導航
    // 如果是從 Terminated 啟動，通常需要在 MaterialApp build 之後導航
    // 這裡我們假設 RichNotificationService 有處理導航的 helper，或者直接使用 AppRouter
    // 為了統一，我們可以複用 RichNotificationService 的 _handleNavigation 邏輯，但它是私有的
    // 所以我們手動處理基本的導航參數轉發

    // 注意：如果是 Background -> Opened，系統不會自動觸發 LocalNotification 的 onTap
    // 因為通知是由系統托盤展示的（對於 notification messages）。
    // 對於 data messages，我們通常在前台或後台生成 LocalNotification，點擊時觸發 onTap

    // 如果是 notification message，點擊會進入這裡。
    // 如果是 data message + local notification，點擊會進入 RichNotificationService 的 onTap。

    // 這裡處理的是 Remote Notification (System Tray) 被點擊
    // 導航邏輯：
    // ...
  }

  /// 用於 RichNotificationService 回調追蹤點擊
  /// 當用戶點擊 *本地* 生成的通知時調用
  Future<void> trackLocalNotificationClick(String notificationId, String? typeStr, String currentUserId) async {
     final notificationType = _parseNotificationType(typeStr ?? 'system');
     await _notificationABService.trackNotificationClicked(
       userId: currentUserId,
       type: notificationType,
       notificationId: notificationId,
     );
  }

  NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'match':
        return NotificationType.match;
      case 'message':
        return NotificationType.message;
      case 'event':
        return NotificationType.event;
      case 'rating':
        return NotificationType.rating;
      default:
        return NotificationType.system;
    }
  }
}

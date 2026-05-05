import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 後台訊息處理器 - 必須是頂層函數
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 如果需要在後台使用其他 Firebase 服務，請確保在此處調用 Firebase.initializeApp
  // 注意：由於這是隔離的 Isolate，RichNotificationService 可能無法直接工作，除非重新初始化
  // 但通常系統會自動處理 data 訊息並顯示（如果有 notification payload）
  debugPrint("Handling a background message: ${message.messageId}");
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

  bool _isInitialized = false;

  /// 初始化通知服務
  ///
  /// [userId] 當前用戶 ID
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;

    // 1. 請求權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      // 2. 獲取 Token 並保存
      await _saveTokenToDatabase(userId);

      // 3. 監聽 Token 刷新
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _firestoreService.updateFcmToken(userId, newToken);
      });

      // 4. 設定前台訊息處理
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');

          // 將 RemoteMessage 轉換為 NotificationModel 並顯示
          _handleForegroundMessage(message, userId);
        }
      });

      // 5. 設定後台訊息處理
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      _isInitialized = true;
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  /// 保存 Token 到資料庫
  Future<void> _saveTokenToDatabase(String userId) async {
    // 獲取 FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint("FCM Token: $token");
      await _firestoreService.updateFcmToken(userId, token);
    }
  }

  /// 處理前台訊息
  void _handleForegroundMessage(RemoteMessage message, String userId) {
    try {
      // 解析 RemoteMessage
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null) {
        // 構建 NotificationModel
        // 注意：RemoteMessage 的 data 欄位通常包含自定義數據
        final data = message.data;

        final model = NotificationModel(
          id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          type: data['type'] ?? 'system',
          title: notification.title ?? '',
          message: notification.body ?? '',
          imageUrl: android?.imageUrl ?? data['imageUrl'],
          actionType: data['actionType'],
          actionData: data['actionData'],
          createdAt: DateTime.now(),
        );

        // 使用 RichNotificationService 顯示
        _richNotificationService.showNotification(model);
      }
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }
}

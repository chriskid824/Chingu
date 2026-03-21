import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';

/// 處理 background/terminated 訊息的 top-level handler
/// 必須是 top-level 函式，不能是 class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
  // Background 訊息由系統通知列自動顯示
  // 無需額外處理，除非需要資料預處理
}

/// FCM 推播通知服務
///
/// 負責：
/// 1. 請求通知權限
/// 2. 取得並儲存 FCM token 到 Firestore
/// 3. 監聽 token 刷新
/// 4. 處理前景訊息（轉本地通知）
/// 5. 處理通知點擊導航
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RichNotificationService _richNotification = RichNotificationService();

  bool _isInitialized = false;

  /// 初始化 FCM 服務
  ///
  /// 應在 Firebase.initializeApp() 之後、runApp() 之前呼叫
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. 註冊 background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. 請求 iOS 權限（Android 在 local notification 已處理）
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // iOS: 設定前景通知呈現方式
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // 3. 訂閱 all_users topic（用於廣播）
    await _messaging.subscribeToTopic('all_users');

    // 4. 監聽前景訊息
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. 監聽通知點擊（App 從 background 被喚醒）
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 6. 處理 terminated 狀態點擊通知啟動的情況
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // 7. 監聽 token 刷新
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });

    _isInitialized = true;
    debugPrint('[FCM] PushNotificationService initialized');
  }

  /// 在用戶登入後呼叫：取得 token 並存入 Firestore
  Future<void> registerUserToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
        debugPrint('[FCM] Token registered for user ${user.uid}');
      }
    } catch (e) {
      debugPrint('[FCM] Error registering token: $e');
    }
  }

  /// 在用戶登出時呼叫：移除 token
  Future<void> unregisterUserToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt': FieldValue.delete(),
        });
        debugPrint('[FCM] Token removed for user ${user.uid}');
      }
    } catch (e) {
      debugPrint('[FCM] Error unregistering token: $e');
    }
  }

  /// 將 FCM token 存入 Firestore user doc
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      'fcmPlatform': Platform.isIOS ? 'ios' : 'android',
    }, SetOptions(merge: true));
  }

  /// 處理前景訊息 — 轉成本地通知顯示
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // 轉換為 NotificationModel 並透過 RichNotificationService 顯示
    final model = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      title: notification.title ?? 'Chingu',
      message: notification.body ?? '',
      type: message.data['type'] ?? 'general',
      createdAt: DateTime.now(),
      isRead: false,
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      imageUrl: notification.android?.imageUrl ?? message.data['imageUrl'],
    );

    _richNotification.showNotification(model);
  }

  /// 處理通知點擊 — 導航到對應頁面
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Notification opened: ${message.data}');
    // 導航邏輯已在 RichNotificationService._onNotificationTap 中處理
    // 這裡可以額外處理 FCM data payload 的特殊導航需求
  }

  /// 訂閱城市 topic（用於地域推播）
  Future<void> subscribeToCityTopic(String city) async {
    final topicName = 'city_${city.toLowerCase().replaceAll(' ', '_')}';
    await _messaging.subscribeToTopic(topicName);
    debugPrint('[FCM] Subscribed to topic: $topicName');
  }

  /// 取消訂閱城市 topic
  Future<void> unsubscribeFromCityTopic(String city) async {
    final topicName = 'city_${city.toLowerCase().replaceAll(' ', '_')}';
    await _messaging.unsubscribeFromTopic(topicName);
    debugPrint('[FCM] Unsubscribed from topic: $topicName');
  }
}

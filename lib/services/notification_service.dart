import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../services/rich_notification_service.dart';
import '../services/firestore_service.dart';
import '../firebase_options.dart';

/// 處理後台訊息的頂層函數
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. 請求權限
    await _requestPermissions();

    // 2. 獲取並保存 Token
    await _updateToken();

    // 3. 監聽 Token 刷新
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // 監聽用戶登入狀態變化，確保登入後更新 Token
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _updateToken();
      }
    });

    // 4. 監聽前台訊息
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. 監聽後台訊息點擊開啟 App
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    _isInitialized = true;
  }

  /// 請求通知權限
  Future<void> _requestPermissions() async {
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
  }

  /// 獲取並更新 Token
  Future<void> _updateToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      await _saveTokenToFirestore(token);
    }
  }

  /// 保存 Token 到 Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {'fcmToken': token});
        debugPrint('Token updated for user: ${user.uid}');
      } catch (e) {
        debugPrint('Error updating token: $e');
      }
    }
  }

  /// 處理前台訊息
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
    }

    // 將 RemoteMessage 轉換為 NotificationModel 並顯示本地通知
    final notificationModel = _mapRemoteMessageToNotificationModel(message);
    RichNotificationService().showNotification(notificationModel);
  }

  /// 處理訊息點擊開啟 App
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message clicked!');
    final notificationModel = _mapRemoteMessageToNotificationModel(message);

    RichNotificationService().handleNavigation(
      notificationModel.actionType,
      notificationModel.actionData,
      notificationModel.id
    );
  }

  /// 檢查冷啟動訊息
  Future<void> checkForInitialMessage() async {
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('App launched from terminated state via notification');
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// 將 RemoteMessage 轉換為 NotificationModel
  NotificationModel _mapRemoteMessageToNotificationModel(RemoteMessage message) {
    // 優先使用 data 中的欄位，因為 notification 欄位可能由系統自動處理
    final Map<String, dynamic> data = message.data;
    final notification = message.notification;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? '新通知',
      message: notification?.body ?? data['body'] ?? data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? (notification?.android?.imageUrl),
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: message.sentTime ?? DateTime.now(),
    );
  }
}

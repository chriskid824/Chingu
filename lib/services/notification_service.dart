import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

/// 處理後台通知的頂層函數
/// 必須在類之外定義
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  // 這裡可以處理後台數據更新，但不要更新 UI
  // 如果需要在這裡處理 Firestore，需要初始化 Firebase
}

class NotificationService {
  // Singleton pattern
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
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {

      // 2. 設置後台處理器
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. 獲取 Token 並保存
      await _updateToken();

      // 4. 監聽 Token 刷新
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

      // 5. 監聽前台訊息
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 6. 監聽 Auth 狀態變化，確保登入後更新 Token
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          _updateToken();
        }
      });

      _isInitialized = true;
    }
  }

  /// 獲取並更新 Token
  Future<void> _updateToken() async {
    try {
      // iOS 需要先獲取 APNS token
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('APNS Token not available yet');
          // 可以在這裡等待或重試，但通常 FCM 會自動處理
        }
      }

      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// 將 Token 保存到 Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {'fcmToken': token});
        debugPrint('FCM Token updated in Firestore');
      } catch (e) {
        debugPrint('Error saving FCM token to Firestore: $e');
      }
    }
  }

  /// 處理前台訊息
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');

      // 構建 NotificationModel 並顯示本地通知
      final notificationModel = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        type: message.data['type'] ?? 'system',
        title: message.notification!.title ?? '',
        message: message.notification!.body ?? '',
        imageUrl: message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl,
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
        createdAt: DateTime.now(),
      );

      RichNotificationService().showNotification(notificationModel);
    }
  }

  /// 刪除 Token (登出時調用)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
         // 可選：從 Firestore 移除 Token
         await _firestoreService.updateUser(user.uid, {'fcmToken': null});
      }
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}

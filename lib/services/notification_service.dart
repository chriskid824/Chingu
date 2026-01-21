import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/core/routes/app_router.dart';

/// 處理後台訊息的頂層函數
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  FirebaseMessaging? _firebaseMessagingTest;
  FirestoreService? _firestoreServiceTest;
  FirebaseAuth? _firebaseAuthTest;
  FirestoreService? _realFirestoreService;

  FirebaseMessaging get _firebaseMessaging =>
      _firebaseMessagingTest ?? FirebaseMessaging.instance;

  FirestoreService get _firestoreService {
    if (_firestoreServiceTest != null) return _firestoreServiceTest!;
    _realFirestoreService ??= FirestoreService();
    return _realFirestoreService!;
  }

  FirebaseAuth get _firebaseAuth => _firebaseAuthTest ?? FirebaseAuth.instance;

  @visibleForTesting
  set firebaseMessaging(FirebaseMessaging instance) =>
      _firebaseMessagingTest = instance;

  @visibleForTesting
  set firestoreService(FirestoreService instance) =>
      _firestoreServiceTest = instance;

  @visibleForTesting
  set firebaseAuth(FirebaseAuth instance) => _firebaseAuthTest = instance;

  String? _fcmToken;

  /// 初始化通知服務
  Future<void> initialize() async {
    // 1. 請求權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. 獲取 Token
      await _getToken();

      // 3. 設置監聽器
      _setupListeners();

      // 4. 檢查是否有初始訊息（當 App 從終止狀態被打開）
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App opened from terminated state via notification');
        _handleNavigation(initialMessage.data);
      }
    }
  }

  /// 獲取 FCM Token
  Future<void> _getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _fcmToken = token;
        debugPrint('FCM Token: $_fcmToken');
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// 設置監聽器
  void _setupListeners() {
    // 監聽 Token 刷新
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      _fcmToken = token;
      debugPrint('FCM Token Refreshed: $_fcmToken');
      _updateTokenInFirestore(token);
    });

    // 監聽 Auth 狀態變化，登入時更新 Token
    _firebaseAuth.authStateChanges().listen((User? user) {
      if (user != null && _fcmToken != null) {
        _updateTokenInFirestore(_fcmToken!);
      }
    });

    // 前台訊息處理
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        // 顯示本地通知
        _showLocalNotification(message);
      }
    });

    // App 從後台被打開
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleNavigation(message.data);
    });
  }

  /// 更新 Firestore 中的 Token
  Future<void> _updateTokenInFirestore(String token) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {
          'fcmToken': token,
        });
        debugPrint('FCM Token updated in Firestore for user: ${user.uid}');
      } catch (e) {
        debugPrint('Error updating FCM token in Firestore: $e');
      }
    }
  }

  /// 顯示本地通知
  void _showLocalNotification(RemoteMessage message) {
    // 嘗試將 RemoteMessage 轉換為 NotificationModel
    // 注意：這裡假設後端發送的 data 結構符合 NotificationModel
    try {
      final notification = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _firebaseAuth.currentUser?.uid ?? '',
        type: message.data['type'] ?? 'system',
        title: message.notification?.title ?? '',
        message: message.notification?.body ?? '',
        imageUrl: message.data['imageUrl'] ?? (message.notification?.android?.imageUrl),
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
        createdAt: DateTime.now(),
      );

      RichNotificationService().showNotification(notification);
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// 處理導航
  void _handleNavigation(Map<String, dynamic> data) {
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    // 這裡重用簡單的導航邏輯，也可以考慮將此邏輯抽離
    switch (actionType) {
      case 'open_chat':
        if (actionData != null) {
          navigator.pushNamed(AppRoutes.chatList);
        } else {
          navigator.pushNamed(AppRoutes.chatList);
        }
        break;
      case 'view_event':
        navigator.pushNamed(AppRoutes.eventDetail);
        break;
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList);
        break;
      default:
        // 預設導航到通知頁面
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }
}

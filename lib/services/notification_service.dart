import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';
import 'notification_ab_service.dart';

/// 背景訊息處理器 - 必須是 Top-level function
/// 這裡不能依賴任何 UI 組件或 Provider
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 確保 Firebase 已在背景初始化（如果需要存取 Firestore 等）
  // await Firebase.initializeApp();
  debugPrint('收到背景通知: ${message.messageId}');
  // 這裡通常不需要做太多事情，因為系統會自動顯示通知
  // 如果是 data-only message，可以在這裡處理本地通知顯示，但通常由後端發送 notification payload
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationABService _abService = NotificationABService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  bool _isInitialized = false;
  RemoteMessage? _initialMessage;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 注意：權限請求應由 UI 層（如 Onboarding 或 Settings）觸發，
    // 這裡不自動請求以免阻塞啟動或造成 UX 問題。
    // 使用 requestPermission 方法手動觸發。

    // 1. 註冊背景處理器
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. 處理前景訊息
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('收到前景訊息: ${message.data}');
      _handleForegroundMessage(message);
    });

    // 3. 處理背景應用程式打開
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('從背景打開應用程式: ${message.data}');
      _handleMessageOpenedApp(message);
    });

    // 4. 處理冷啟動 (Terminated -> Opened)
    // 我們只記錄不立即執行，等待 UI 準備好（在 MainScreen 調用 processInitialMessage）
    _initialMessage = await _firebaseMessaging.getInitialMessage();
    if (_initialMessage != null) {
      debugPrint('從冷啟動打開應用程式 (Pending): ${_initialMessage!.data}');
    }

    // 5. 監聽 Token 刷新
    _firebaseMessaging.onTokenRefresh.listen((fcmToken) {
      _updateToken(fcmToken);
    }).onError((err) {
      debugPrint('Token refresh error: $err');
    });

    // 6. 監聽 Auth 狀態變化以更新 Token
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _updateCurrentToken();
      }
    });

    _isInitialized = true;
  }

  /// 請求通知權限 (供 UI 調用)
  Future<bool> requestPermission() async {
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

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _updateCurrentToken();
      return true;
    }
    return false;
  }

  /// 更新當前 FCM Token 到 Firestore
  Future<void> _updateCurrentToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _updateToken(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// 更新 Token 到 Firestore
  Future<void> _updateToken(String token) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          // 也可以維護一個 tokens 陣列以支持多設備
          // 'fcmTokens': FieldValue.arrayUnion([token]),
        });
        debugPrint('FCM Token updated for user ${user.uid}');
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }
    }
  }

  /// 處理前景訊息
  void _handleForegroundMessage(RemoteMessage message) {
    // 解析 NotificationModel
    // 如果是 Notification Message (含有 notification 欄位)，Firebase SDK 會自動處理顯示（但在前景不會顯示，除非我們自己顯示）
    // 如果是 Data Message，我們需要自己構建通知

    // 優先使用 notification 欄位，如果沒有則使用 data 構建
    String title = message.notification?.title ?? '';
    String body = message.notification?.body ?? '';

    // 從 data 中解析類型
    String typeStr = message.data['type'] ?? 'system';
    NotificationType type = _parseNotificationType(typeStr);

    // 如果是 Data Message 且沒有標題/內容，使用 AB Service 生成
    if (title.isEmpty || body.isEmpty) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final content = _abService.getContent(user.uid, type, params: message.data);
        title = content.title;
        body = content.body;
      } else {
        // Fallback
        title = '新通知';
        body = '您收到一則新訊息';
      }
    }

    // 構建 NotificationModel 用於 RichNotificationService
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      type: typeStr,
      title: title,
      message: body,
      imageUrl: message.notification?.android?.imageUrl ?? message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'], // 可能是 JSON 或 ID
      createdAt: DateTime.now(),
    );

    // 顯示本地通知
    _richNotificationService.showNotification(notification);
  }

  /// 處理從通知打開應用
  void _handleMessageOpenedApp(RemoteMessage message) {
    // 解析 Payload
    final String? actionType = message.data['actionType'];
    final String? actionData = message.data['actionData'];

    if (actionType != null) {
      debugPrint('Handling navigation for action: $actionType');

      // 使用 RichNotificationService 統一的導航邏輯
      // 延遲一下以確保應用完全喚醒
       Future.delayed(const Duration(milliseconds: 200), () {
          _richNotificationService.handleNavigation(actionType, actionData, null);
       });
    }
  }

  NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'match':
        return NotificationType.match;
      case 'event':
        return NotificationType.event;
      case 'message':
        return NotificationType.message;
      case 'rating':
        return NotificationType.rating;
      default:
        return NotificationType.system;
    }
  }

  /// 處理並消耗待處理的初始訊息 (由 UI 層在就緒時調用)
  void processPendingInitialMessage() {
    if (_initialMessage != null) {
      debugPrint('Processing pending initial message: ${_initialMessage!.data}');
      _handleMessageOpenedApp(_initialMessage!);
      _initialMessage = null;
    }
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';
import 'firestore_service.dart';
import 'rich_notification_service.dart';

/// 背景消息處理程序
/// 必須是頂層函數，並標記為 @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 確保 Firebase 已初始化
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Dependencies that can be injected/mocked
  FirestoreService _firestoreService = FirestoreService();
  RichNotificationService _richNotificationService = RichNotificationService();

  bool _isInitialized = false;

  /// 設置依賴（用於測試）
  void setDependencies({
    FirestoreService? firestoreService,
    RichNotificationService? richNotificationService,
  }) {
    if (firestoreService != null) _firestoreService = firestoreService;
    if (richNotificationService != null) _richNotificationService = richNotificationService;
  }

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 設置背景處理程序
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 請求權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 監聽 Token 刷新
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // 監聽前台消息
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 監聽通知點擊（應用從後台打開）
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 監聽登入狀態以同步 Token
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _updateFcmToken();
      }
    });

    // 獲取初始消息但不立即處理，等待導航器就緒
    _initialMessage = await _firebaseMessaging.getInitialMessage();

    _isInitialized = true;
  }

  RemoteMessage? _initialMessage;

  /// 處理應用啟動時的初始消息
  /// 應在導航器就緒後調用（例如 MainScreen 的 initState 或 PostFrameCallback）
  void processInitialMessage() {
    if (_initialMessage != null) {
      _handleMessageOpenedApp(_initialMessage!);
      _initialMessage = null; // 處理後清除，避免重複處理
    }
  }

  /// 更新 FCM Token
  Future<void> _updateFcmToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// 將 Token 儲存到 Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token saved to Firestore');
      } catch (e) {
        debugPrint('Error saving FCM token to Firestore: $e');
      }
    }
    // 如果用戶未登入，authStateChanges 監聽器會在登入後處理
  }

  /// 處理前台消息
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');

    // 如果有通知負載，顯示本地通知
    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');

      final notificationModel = _createNotificationModelFromRemoteMessage(message);
      _richNotificationService.showNotification(notificationModel);
    }
  }

  /// 處理通知點擊開啟應用
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('A new onMessageOpenedApp event was published!');

    final data = message.data;
    final String? actionType = data['actionType'];
    final String? actionData = data['actionData'];

    _handleNavigation(actionType, actionData);
  }

  /// 處理導航邏輯
  void _handleNavigation(String? actionType, String? actionData) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('Navigator state is null, cannot navigate');
      return;
    }

    debugPrint('Navigating to action: $actionType with data: $actionData');

    switch (actionType) {
      case 'open_chat':
        navigator.pushNamed(AppRoutes.chatList);
        break;
      case 'view_event':
        // 暫時導航到詳情頁，忽略具體 ID 因為 EventDetailScreen 可能需要參數調整
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

  /// 輔助方法：從 RemoteMessage 創建 NotificationModel
  NotificationModel _createNotificationModelFromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    final user = _auth.currentUser;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user?.uid ?? '',
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? 'New Notification',
      message: notification?.body ?? data['message'] ?? '',
      imageUrl: data['imageUrl'] ?? (notification?.android?.imageUrl),
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: DateTime.now(),
      isRead: false,
    );
  }
}

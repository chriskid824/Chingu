import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

/// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. 請求權限
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. 設定後台消息處理器
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. 設定前台消息監聽
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 4. 設定後台點擊監聽 (App 從後台開啟)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // 5. 處理 App 從終止狀態開啟的消息
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      // 6. 處理 Token
      await updateToken();
      _messaging.onTokenRefresh.listen(_saveTokenToDatabase);

      _isInitialized = true;
    }
  }

  /// 處理前台消息
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');

      // 將 RemoteMessage 轉換為 NotificationModel 並顯示
      final notificationModel = _createNotificationModelFromRemoteMessage(message);
      _richNotificationService.showNotification(notificationModel);
    }
  }

  /// 處理消息點擊 (App 開啟)
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');
    // 這裡通常不需要特別處理，因為 RichNotificationService 在初始化時會處理本地通知的點擊
    // 如果是從 FCM 的系統通知點擊進來，可能需要導航邏輯
    // 目前 AppRouter 和 RichNotificationService 似乎已經處理了導航
    // 如果需要處理 data-only 消息的導航，可以在這裡添加邏輯
  }

  /// 更新並儲存 FCM Token
  Future<void> updateToken() async {
    try {
      String? token = await _messaging.getToken();
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
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {'fcmToken': token});
        debugPrint('FCM Token saved to Firestore');
      } catch (e) {
        debugPrint('Error saving FCM token to Firestore: $e');
      }
    }
  }

  /// 輔助方法：從 RemoteMessage 創建 NotificationModel
  NotificationModel _createNotificationModelFromRemoteMessage(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? message.data['title'] ?? '',
      message: message.notification?.body ?? message.data['body'] ?? '',
      imageUrl: message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );
  }
}

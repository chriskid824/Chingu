import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 背景訊息處理器
/// 必須是 Top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 確保 Firebase 已在背景初始化 (在 main.dart 中處理，但這裡是獨立 isolate)
  // 如果在此 handler 中需要使用 Firestore 等服務，必須在此處調用 await Firebase.initializeApp();
  // 注意：這是在獨立的 isolate 中運行，無法訪問主 isolate 的內存或 UI

  debugPrint('Handling a background message: ${message.messageId}');

  // 這裡可以選擇是否顯示本地通知，或者讓系統托盤自動處理（針對 notification 類型的消息）
  // 對於 data 類型的消息，可以在這裡處理邏輯
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
  Future<void> initialize() async {
    if (_isInitialized) return;

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
      return;
    }

    // 獲取並保存 Token
    await _saveTokenToDatabase();

    // 監聽 Token 刷新
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // 設置前台訊息監聽
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 設置後台訊息點擊監聽 (App 從後台被打開)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 檢查是否有初始訊息 (App 從關閉狀態被打開)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // 監聽登入狀態變化，確保登入後保存 Token
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _saveTokenToDatabase();
      }
    });

    _isInitialized = true;
  }

  /// 獲取並保存 Token 到 Firestore
  Future<void> _saveTokenToDatabase([String? token]) async {
    String? fcmToken = token ?? await _firebaseMessaging.getToken();

    if (fcmToken != null) {
      debugPrint('FCM Token: $fcmToken');

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _firestoreService.updateFcmToken(currentUser.uid, fcmToken);
      }
    }
  }

  /// 處理前台訊息
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');

      // 將 RemoteMessage 轉換為 NotificationModel 並顯示
      final notification = _convertToNotificationModel(message);
      _richNotificationService.showNotification(notification);
    }
  }

  /// 處理訊息點擊 (後台或關閉狀態)
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message clicked!');
    // 這裡的邏輯可能需要配合 AppRouter 或 RichNotificationService 的導航邏輯
    // 目前 RichNotificationService 處理了本地通知的點擊，
    // 對於 FCM 點擊，如果是 data message，可能需要手動導航

    // 如果消息包含 payload (通常在 data 中)，可以解析並導航
    if (message.data.isNotEmpty) {
      // 這裡可以調用 RichNotificationService 的內部邏輯或直接使用 Navigator
      // 但由於 RichNotificationService 主要處理本地通知的回調，
      // 這裡我們可能需要提取 data 中的 actionType 和 actionData 來導航
      // 暫時僅打印日誌，實際導航邏輯視 App 結構而定
      // 若要實現導航，可能需要用到全局 NavigatorKey
    }
  }

  /// 將 RemoteMessage 轉換為 NotificationModel
  NotificationModel _convertToNotificationModel(RemoteMessage message) {
    // 解析 RemoteMessage 構建 NotificationModel
    // 這裡需要根據後端發送的格式進行解析
    final data = message.data;
    final notification = message.notification;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification?.title ?? '新通知',
      message: notification?.body ?? '',
      type: data['type'] ?? 'system',
      timestamp: message.sentTime ?? DateTime.now(),
      isRead: false,
      imageUrl: data['imageUrl'] ?? notification?.android?.imageUrl,
      actionType: data['actionType'],
      actionData: data['actionData'],
      deeplink: data['deeplink'],
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
    );
  }

  /// 手動獲取 Token (供外部調用)
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

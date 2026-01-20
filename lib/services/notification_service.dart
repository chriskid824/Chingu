import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/rich_notification_service.dart';

/// 背景訊息處理器 - 必須是頂層函數
/// 處理 App 在背景或被終止時收到的訊息
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 確保 Firebase 已初始化
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
  // 注意：在此處不進行導航，因為 App 可能在背景運行。
  // 如果需要顯示通知，系統會根據 notification payload 自動顯示。
  // 如果是 data payload，則可能需要手動觸發本地通知（視需求而定）。
}

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
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

    // 2. 註冊背景訊息處理器
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. 處理 App 被終止後，點擊通知開啟 App 的情況
    // getInitialMessage() 會返回觸發 App 開啟的那則訊息
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageNavigation(initialMessage);
    }

    // 4. 處理 App 在背景時，點擊通知開啟 App 的情況
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

    // 5. 處理 App 在前景時收到的訊息
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // 前景收到通知時，Firebase 不會自動顯示通知
        // 這裡可以選擇使用 RichNotificationService 顯示本地通知
        // 或者直接處理（例如更新 UI badge）
      }
    });

    _isInitialized = true;
  }

  /// 處理訊息導航
  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    debugPrint("Handling navigation for message: ${message.messageId}, data: $data");

    // 從 data 中提取 actionType 和 actionData
    // 假設後端發送的格式包含這些欄位
    final String? actionType = data['actionType'];
    final String? actionData = data['actionData'];
    // actionId 在這裡通常為 null，除非 payload 有特別指定
    final String? actionId = data['actionId'];

    // 使用 RichNotificationService 的導航邏輯
    RichNotificationService().handleNavigation(actionType, actionData, actionId);
  }

  /// 獲取 FCM Token
  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// 監聽 Token 刷新
  Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;
}

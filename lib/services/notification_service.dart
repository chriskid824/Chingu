import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';

/// 背景訊息處理器 (必須是 top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 確保 Firebase 已初始化
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");

  // 在這裡可以處理背景訊息，例如更新本地儲存或顯示本地通知
  // 如果是 data message，且需要顯示通知，可以在這裡調用 RichNotificationService
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

    // 註冊背景處理器
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 監聽前景訊息
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      _handleForegroundMessage(message);
    });

    // 監聽背景/關閉狀態點擊應用程式開啟
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 檢查應用程式是否從終止狀態開啟
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    _isInitialized = true;
  }

  /// 處理前景訊息
  void _handleForegroundMessage(RemoteMessage message) {
    // 將 RemoteMessage 轉換為 NotificationModel
    // 如果有 notification payload，優先使用其中的 title/body
    // 否則使用 data 中的 title/message

    Map<String, dynamic> data = Map<String, dynamic>.from(message.data);

    if (message.notification != null) {
      data['title'] = message.notification!.title ?? data['title'];
      data['message'] = message.notification!.body ?? data['message'];
    }

    // 確保有必要的欄位 (NotificationModel 需要 title 和 message)
    if (data['title'] == null) data['title'] = '新通知';
    if (data['message'] == null) data['message'] = '';

    try {
      final notification = NotificationModel.fromMap(
        data,
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString()
      );

      // 顯示豐富通知
      RichNotificationService().showNotification(notification);
    } catch (e) {
      debugPrint('Error creating notification model: $e');
    }
  }

  /// 處理從通知開啟應用程式
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('A new onMessageOpenedApp event was published!');

    final Map<String, dynamic> data = message.data;
    final String? actionType = data['actionType'];
    final String? actionData = data['actionData'];

    // 使用 RichNotificationService 的導航邏輯
    RichNotificationService().handleNavigation(actionType, actionData, null);
  }

  /// 獲取 FCM Token (用於測試或後端整合)
  Future<String?> getDeviceToken() async {
    return await _firebaseMessaging.getToken();
  }
}

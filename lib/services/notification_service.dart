import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../models/notification_model.dart';
import 'rich_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 確保 Firebase 初始化
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
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
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 設置背景訊息處理器
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 監聽前景訊息
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      // 顯示本地通知
      final notificationModel = _createNotificationFromRemoteMessage(message);
      RichNotificationService().showNotification(notificationModel);
    });

    // 處理從背景狀態開啟 App
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageInteraction);

    _isInitialized = true;
  }

  /// 處理從終止狀態開啟 App
  /// 應在 UI 初始化完成後調用 (例如在 MainScreen 的 initState)
  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageInteraction(initialMessage);
    }
  }

  /// 處理訊息點擊互動
  void _handleMessageInteraction(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    debugPrint('Handling message interaction: actionType=$actionType, actionData=$actionData');

    RichNotificationService().handleNavigation(actionType, actionData);
  }

  /// 將 RemoteMessage 轉換為 NotificationModel
  NotificationModel _createNotificationFromRemoteMessage(RemoteMessage message) {
    final data = message.data;

    // 嘗試獲取圖片 URL
    String? imageUrl = message.notification?.android?.imageUrl ??
                       message.notification?.apple?.imageUrl ??
                       data['imageUrl'];

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: data['userId'] ?? '', // 如果 data 中沒有 userId，則為空
      type: data['type'] ?? 'system',
      title: message.notification?.title ?? data['title'] ?? '通知',
      message: message.notification?.body ?? data['message'] ?? '',
      imageUrl: imageUrl,
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: message.sentTime ?? DateTime.now(),
    );
  }
}

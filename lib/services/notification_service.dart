import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/routes/app_router.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 確保 Firebase 已初始化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 請求權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 設置背景訊息處理器
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 設置互動訊息處理 (背景/終止狀態點擊)
    setupInteractedMessage();

    // 監聽前景訊息 (如果需要，可以在這裡呼叫 RichNotificationService 顯示通知)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
       debugPrint('Got a message whilst in the foreground!');
       debugPrint('Message data: ${message.data}');
       if (message.notification != null) {
         debugPrint('Message also contained a notification: ${message.notification}');
         // TODO: 整合 RichNotificationService 顯示前景通知
       }
    });

    _isInitialized = true;
  }

  Future<void> setupInteractedMessage() async {
    // 處理應用程式從終止狀態被打開的情況
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // 處理應用程式從背景狀態被打開的情況
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    debugPrint('Notification tapped with action: $actionType, data: $actionData');

    _handleNavigation(actionType, actionData);
  }

  void _handleNavigation(String? actionType, String? actionData) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('Navigator is null, cannot navigate');
      return;
    }

    switch (actionType) {
      case 'open_chat':
        if (actionData != null) {
          // 導航到聊天列表，因為 ChatDetailScreen 需要特定參數，
          // 這裡簡化處理，或者如果有足夠資訊可以構建參數
          // 假設 actionData 是 userId 或 chatRoomId
          // 暫時導航到聊天列表
          navigator.pushNamed(AppRoutes.chatList);
        } else {
          navigator.pushNamed(AppRoutes.chatList);
        }
        break;
      case 'view_event':
         // 類似 RichNotificationService 的處理
        navigator.pushNamed(AppRoutes.eventsList);
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

  // 獲取 FCM Token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

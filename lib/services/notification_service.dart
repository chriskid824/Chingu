import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  // 這裡不需要初始化 Firebase，因為我們不使用其他 Firebase 服務
  // 如果需要存取 Firestore 或 Auth，則需要 await Firebase.initializeApp();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. 請求權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. 獲取並印出 Token (實際應用中應上傳至伺服器)
    String? token = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');

    // 3. 監聽前台訊息
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        // 轉換為 NotificationModel 並顯示
        final model = NotificationModel(
          id: message.messageId ?? DateTime.now().toString(),
          userId: '', // 前台顯示不需要
          type: message.data['type'] ?? 'system',
          title: message.notification?.title ?? '',
          message: message.notification?.body ?? '',
          imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
          actionType: message.data['actionType'],
          actionData: message.data['actionData'],
          createdAt: DateTime.now(),
        );

        RichNotificationService().showNotification(model);
      }
    });

    // 4. 監聽後台/已關閉 App 被開啟的事件 (當用戶點擊通知)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');

      final actionType = message.data['actionType'];
      final actionData = message.data['actionData'];

      RichNotificationService().handleNavigation(actionType, actionData, null);
    });
  }

  /// 獲取初始啟動的路由資訊 (Terminated 狀態)
  Future<Map<String, dynamic>?> getInitialNotificationRoute() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('App launched from terminated state via notification');

      final actionType = initialMessage.data['actionType'];
      // final actionData = initialMessage.data['actionData']; // 目前路由不需要參數

      String route = _getRouteFromAction(actionType);

      return {
        'route': route,
        'arguments': null, // 暫時無參數
      };
    }
    return null;
  }

  String _getRouteFromAction(String? action) {
    switch (action) {
      case 'open_chat':
        return AppRoutes.chatList;
      case 'view_event':
        return AppRoutes.eventDetail;
      case 'match_history':
        return AppRoutes.matchesList;
      default:
        return AppRoutes.notifications;
    }
  }
}

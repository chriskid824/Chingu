import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> initialize() async {
    // 請求通知權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 設置後台訊息處理
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 處理前台訊息
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      _showForegroundNotification(message);
    });

    // 處理應用程式開啟時的訊息
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageNavigation(message);
    });

    // 監聽 Token 更新
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });
  }

  /// 檢查初始訊息 (解決 Cold Start Navigation 問題)
  Future<void> checkForInitialMessage() async {
    try {
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('Found initial message for cold start');
        _handleMessageNavigation(initialMessage);
      }
    } catch (e) {
      debugPrint('Error checking for initial message: $e');
    }
  }

  /// 更新用戶 Token
  Future<void> updateUserToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestoreService.updateUser(userId, {'fcmToken': token});
        debugPrint('FCM Token updated for user: $userId');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// 儲存 Token 到 Firestore (內部使用)
  Future<void> _saveTokenToFirestore(String token) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestoreService.updateUser(user.uid, {'fcmToken': token});
      debugPrint('FCM Token refreshed and saved for user: ${user.uid}');
    }
  }

  /// 顯示前台通知
  void _showForegroundNotification(RemoteMessage message) {
    // 構建 NotificationModel
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? message.data['title'] ?? '通知',
      message: message.notification?.body ?? message.data['body'] ?? '',
      imageUrl: message.data['imageUrl'] ?? message.notification?.android?.imageUrl,
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: message.sentTime ?? DateTime.now(),
    );

    // 使用 RichNotificationService 顯示通知
    RichNotificationService().showNotification(notification);
  }

  /// 處理訊息導航
  void _handleMessageNavigation(RemoteMessage message) {
    final actionType = message.data['actionType'];
    final actionData = message.data['actionData'];
    // actionId 在 RemoteMessage 中通常對應 action click，這裡主要是 payload 的處理
    // 如果是點擊通知本身，我們只關注 payload 裡的 actionType/actionData

    RichNotificationService().handleNavigation(actionType, actionData, null);
  }
}

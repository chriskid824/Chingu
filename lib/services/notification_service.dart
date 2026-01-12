import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

/// 核心通知服務
/// 負責 FCM 初始化、Token 管理和消息監聽
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  bool _isInitialized = false;

  /// 初始化通知服務
  ///
  /// [userId] 當前用戶 ID (若已登入)
  Future<void> initialize(String? userId) async {
    if (_isInitialized) return;

    try {
      // 1. 請求權限
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
         debugPrint('User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
         debugPrint('User granted provisional notification permission');
      } else {
         debugPrint('User declined or has not accepted notification permission');
         // 即使沒權限，我們仍繼續初始化以便獲取 token (某些情況下仍可用)
      }

      // 2. 獲取 Token 並更新
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        if (userId != null) {
          await _updateToken(userId, token);
        }
      }

      // 3. 監聽 Token 刷新
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        if (userId != null) {
          _updateToken(userId, newToken);
        }
      });

      // 4. 監聽前台消息
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
         debugPrint('Received foreground message: ${message.messageId}');

         if (message.notification != null) {
           debugPrint('Message also contained a notification: ${message.notification}');
           // 這裡可以整合 RichNotificationService 顯示本地通知
           // 因為 FCM SDK 在前台默認不顯示通知
         }
      });

      // 5. 處理後台消息點擊打開 App
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Message opened app: ${message.messageId}');
        // 這裡可以處理導航邏輯，通常交給路由或 RichNotificationService 處理
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
    }
  }

  /// 更新 Firestore 中的 Token
  Future<void> _updateToken(String userId, String token) async {
    try {
      await _firestoreService.updateFcmToken(userId, token);
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// 手動刷新 Token (例如用戶登入後)
  Future<void> refreshUserToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _updateToken(userId, token);
      }
    } catch (e) {
      debugPrint('Failed to refresh user token: $e');
    }
  }
}

/// 後台消息處理器
/// 必須是頂層函數
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 注意：在後台處理器中無法訪問應用程序的狀態或 UI
  debugPrint("Handling a background message: ${message.messageId}");
}

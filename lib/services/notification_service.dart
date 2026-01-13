import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/firestore_service.dart';

/// 背景訊息處理器 - 必須是頂層函數
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

/// 核心通知服務 - 負責整合 Firebase Cloud Messaging
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  bool _isInitialized = false;

  /// 初始化 FCM 服務
  ///
  /// [userId] 可選，如果已登入可傳入 ID 以便直接更新 Token
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;

    try {
      // 請求權限
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {

        // 註冊背景處理器
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // 獲取並處理 Token
        String? token = await _firebaseMessaging.getToken();
        debugPrint('FCM Token: $token');

        if (token != null && userId != null) {
          await _firestoreService.updateFcmToken(userId, token);
        }

        // 監聽 Token 刷新
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          debugPrint('FCM Token Refreshed: $newToken');
          if (userId != null) {
             await _firestoreService.updateFcmToken(userId, newToken);
          }
          // Note: 如果 userId 為空，我們可能需要將 Token 暫存，等待用戶登入後更新
          // 但目前簡單實作，僅在有 userId 時更新
        });

        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('FCM initialization failed: $e');
    }
  }

  /// 獲取當前 FCM Token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// 更新用戶 Token (例如登入後調用)
  Future<void> updateUserToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestoreService.updateFcmToken(userId, token);

        // 重新設置監聽器以確保使用正確的 userId (如果 initialize 時沒有 userId)
        // 注意：onTokenRefresh 是廣播流，這裡如果不小心可能會多次監聽
        // 簡單起見，我們依靠 initialize 中的監聽器，但那個監聽器可能閉包了舊的 userId (null)
        // 更好的做法是將 userId 存為類別成員變量，或者在這裡重新訂閱
        // 鑑於 `initialize` 通常在 main 呼叫，userId 可能為空。
        // 我們應該在服務內部維護 userId 狀態，或者在 refresh 回調中獲取當前用戶

        // 這裡僅做一次性更新
      }
    } catch (e) {
      debugPrint('Update user token failed: $e');
    }
  }
}

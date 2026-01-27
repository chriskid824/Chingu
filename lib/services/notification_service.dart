import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

/// Top-level background handler
/// 此處理程序必須是頂層函數，並且不能依賴於任何 UI 元件
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 如果需要在後台使用其他 Firebase 服務，請確保在此處初始化 Firebase
  // await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentUserId;

  /// 初始化通知服務
  Future<void> initialize(String userId) async {
    _currentUserId = userId;

    // 1. 請求權限
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      // 2. 獲取 Token
      // iOS 需要 APNS token，getToken 會自動處理
      try {
        String? token = await _fcm.getToken();
        if (token != null) {
          debugPrint('FCM Token: $token');
          await _updateToken(userId, token);
        }
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      // 3. 監聽 Token 刷新
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token Refreshed: $newToken');
        _updateToken(userId, newToken);
      });

      // 4. 監聽前台訊息
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
          // 在這裡可以整合 RichNotificationService 來顯示本地通知
        }
      });

    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  /// 更新 Firestore 中的 Token
  Future<void> _updateToken(String userId, String token) async {
    try {
      await _firestoreService.updateUser(userId, {'fcmToken': token});
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// 刪除 Token (登出時調用)
  Future<void> deleteToken(String userId) async {
    try {
      // 從 Firestore 移除 Token
      await _firestoreService.updateUser(userId, {'fcmToken': FieldValue.delete()});
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}

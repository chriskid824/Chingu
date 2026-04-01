import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

/// 核心通知服務 - 處理 FCM 整合
class NotificationService {
  final FirebaseMessaging _messaging;
  final FirestoreService _firestoreService;
  StreamSubscription<String>? _tokenRefreshSubscription;

  NotificationService({
    FirebaseMessaging? messaging,
    FirestoreService? firestoreService,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  /// 初始化通知服務
  /// 請求權限
  Future<void> initialize() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  /// 獲取當前 FCM Token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// 註冊 Token 到 Firestore
  ///
  /// [userId] 用戶 ID
  Future<void> registerToken(String userId) async {
    try {
      final token = await getToken();
      if (token != null) {
        await _firestoreService.updateUser(userId, {'fcmToken': token});
        debugPrint('FCM Token registered for user $userId');
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
      // 不拋出異常，以免中斷主流程
    }
  }

  /// 監聽 Token 刷新事件
  ///
  /// [userId] 用戶 ID
  void monitorTokenRefresh(String userId) {
    try {
      // 取消舊的訂閱以避免重複監聽
      _tokenRefreshSubscription?.cancel();

      _tokenRefreshSubscription =
          _messaging.onTokenRefresh.listen((newToken) async {
        try {
          await _firestoreService.updateUser(userId, {'fcmToken': newToken});
          debugPrint('FCM Token updated for user $userId');
        } catch (e) {
          debugPrint('Error updating FCM token refresh: $e');
        }
      });
    } catch (e) {
      debugPrint('Error setting up token refresh monitor: $e');
    }
  }

  /// 釋放資源
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}

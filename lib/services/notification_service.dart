import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/firestore_service.dart';

/// 通知服務 - 負責 FCM 整合與 Token 管理
class NotificationService {
  final FirebaseMessaging _firebaseMessaging;
  final FirestoreService _firestoreService;

  NotificationService({
    FirestoreService? firestoreService,
    FirebaseMessaging? firebaseMessaging,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance;

  /// 初始化通知服務
  ///
  /// [userId] 當前登入的用戶 ID
  Future<void> initialize(String userId) async {
    // 請求權限
    await requestPermission();

    // 獲取並更新 Token
    await _updateToken(userId);

    // 監聽 Token 刷新
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _firestoreService.updateFcmToken(userId, token);
    });

    // 處理前景訊息 (可選，根據需求擴展)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('收到前景訊息: ${message.notification?.title}');
      }
    });
  }

  /// 請求通知權限
  Future<void> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }
  }

  /// 獲取並更新 Token
  Future<void> _updateToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }

      if (token != null) {
        await _firestoreService.updateFcmToken(userId, token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  /// 獲取當前 Token (用於調試)
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

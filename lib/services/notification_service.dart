import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// 通知服務 - 負責處理 FCM Token、接收通知以及發送通知
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// 初始化通知服務
  ///
  /// 請求權限並設置 Token 刷新監聽
  Future<void> initialize() async {
    try {
      // 1. 請求權限
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('使用者已授權通知');

        // 2. 獲取並保存 Token
        final token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
        }

        // 3. 監聽 Token 刷新
        _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

        // 4. 設定前景/背景訊息處理 (由 RichNotificationService 和 main.dart 處理)
      } else {
        debugPrint('使用者拒絕或未授權通知');
      }
    } catch (e) {
      debugPrint('初始化通知服務失敗: $e');
    }
  }

  /// 保存 FCM Token 到 Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    // 這裡需要獲取當前用戶 ID，通常由 AuthProvider 提供，或者從 FirebaseAuth 獲取
    // 由於 NotificationService 是單例且可能在 AuthProvider 之前初始化，
    // 我們可以依賴 FirebaseAuth.instance (但為了保持依賴清晰，這裡暫時不引入 FirebaseAuth)
    // 實際應用中，Token 更新通常在用戶登入後進行
    // 我們假設調用此方法時用戶已登入，或者透過 AuthProvider 調用
    // 這裡我們暫時只打印，具體保存邏輯可能在 AuthProvider 登入成功後調用

    // 修正：記憶中提到 "manages FCM tokens (updating fcmToken and lastTokenUpdate directly in Firestore)"
    // 我們應該提供一個公開方法供 AuthProvider 調用
    debugPrint('FCM Token: $token');
  }

  /// 更新用戶的 FCM Token
  ///
  /// [userId] 用戶 ID
  Future<void> updateUserToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('更新 FCM Token 失敗: $e');
    }
  }

  /// 發送配對成功通知給雙方
  ///
  /// [userId] 用戶 A ID
  /// [targetUserId] 用戶 B ID
  ///
  /// 調用 Cloud Function `sendMatchNotification`
  Future<void> sendMatchNotification(String userId, String targetUserId) async {
    try {
      final callable = _functions.httpsCallable('sendMatchNotification');
      await callable.call({
        'userId': userId,
        'targetUserId': targetUserId,
      });
      debugPrint('已發送配對通知給 $userId 和 $targetUserId');
    } catch (e) {
      debugPrint('發送配對通知失敗: $e');
      // 不拋出異常，以免影響主要配對流程
    }
  }
}

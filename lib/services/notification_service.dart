import 'package:chingu/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// 通知服務 - 處理 FCM 相關功能
class NotificationService {
  final FirebaseMessaging _firebaseMessaging;
  final FirestoreService _firestoreService;
  final FirebaseAuth _firebaseAuth;

  NotificationService({
    FirebaseMessaging? firebaseMessaging,
    FirestoreService? firestoreService,
    FirebaseAuth? firebaseAuth,
  })  : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _firestoreService = firestoreService ?? FirestoreService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// 初始化通知服務
  Future<void> initialize() async {
    // 1. 請求權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // 暫時性權限（主要用於 iOS）
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('用戶已授權通知權限');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('用戶已授權暫時性通知權限');
    } else {
      debugPrint('用戶拒絕或未授權通知權限');
      return;
    }

    // 2. 獲取 Token
    // 在 iOS 上，需要 APNS Token 才能獲取 FCM Token
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken == null) {
        debugPrint('無法獲取 APNS Token，可能是在模擬器上運行或未配置推送證書');
        // 在模擬器上可能無法獲取，但我們繼續嘗試獲取 FCM Token
      }
    }

    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('獲取 FCM Token 失敗: $e');
    }

    // 3. 監聽 Token 刷新
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

    // 4. 監聽 Auth 狀態變化，登入時同步 Token
    _firebaseAuth.authStateChanges().listen((User? user) {
      if (user != null) {
        _syncTokenOnLogin();
      }
    });
  }

  /// 登入時同步 Token
  Future<void> _syncTokenOnLogin() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('登入同步 Token 失敗: $e');
    }
  }

  /// 當 Token 刷新時的回調
  Future<void> _onTokenRefresh(String newToken) async {
    debugPrint('FCM Token 刷新: $newToken');
    await _saveTokenToFirestore(newToken);
  }

  /// 將 Token 保存到 Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {
          'fcmToken': token,
        });
        debugPrint('FCM Token 已更新到 Firestore');
      } catch (e) {
        debugPrint('更新 FCM Token 到 Firestore 失敗: $e');
      }
    } else {
      debugPrint('用戶未登入，跳過保存 Token');
    }
  }

  /// 手動獲取當前 Token (可供外部調用)
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

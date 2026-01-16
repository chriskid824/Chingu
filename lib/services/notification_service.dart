import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

/// 核心通知服務 - 處理 FCM 初始化、Token 管理
class NotificationService {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  FirestoreService _firestoreService = FirestoreService();
  FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// 設置依賴（用於測試）
  @visibleForTesting
  void setDependencies({
    required FirebaseMessaging firebaseMessaging,
    required FirestoreService firestoreService,
    required FirebaseAuth auth,
  }) {
    _firebaseMessaging = firebaseMessaging;
    _firestoreService = firestoreService;
    _auth = auth;
  }

  /// 初始化通知服務
  Future<void> initialize() async {
    // 請求權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');

      // 獲取初始 Token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // 監聽 Token 刷新
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

      // 監聽登入狀態變化，確保登入後更新 Token
      _auth.authStateChanges().listen((User? user) async {
        if (user != null) {
           String? currentToken = await _firebaseMessaging.getToken();
           if (currentToken != null) {
             await _saveTokenToFirestore(currentToken);
           }
        }
      });

    } else {
      debugPrint('User declined or has not accepted notification permission');
    }
  }

  /// 儲存 Token 到 Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {'fcmToken': token});
        debugPrint('FCM Token updated for user ${user.uid}');
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }
    } else {
       debugPrint('No user logged in, skipping FCM token save');
    }
  }
}

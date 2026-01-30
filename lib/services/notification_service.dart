import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// 初始化通知服務
  Future<void> initialize() async {
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

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // 監聽 Token 刷新事件
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  /// 註冊 FCM Token 並儲存到 Firestore
  ///
  /// [userId] 用戶 ID
  Future<void> registerToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('FCM Token: $token');
        }
        await _firestoreService.updateUser(userId, {'fcmToken': token});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  /// 將 Token 儲存到 Firestore (用於 Token 刷新)
  Future<void> _saveTokenToFirestore(String token) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {'fcmToken': token});
        if (kDebugMode) {
          print('FCM Token saved to Firestore for user: ${user.uid}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error saving FCM token to Firestore: $e');
        }
      }
    }
  }
}

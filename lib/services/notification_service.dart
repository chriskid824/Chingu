import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 初始化通知服務
  Future<void> initialize() async {
    // 請求權限
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

    // 監聽 Token 刷新
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  /// 獲取 FCM Token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// 檢查並儲存 Token 到 Firestore
  ///
  /// [uid] 用戶 ID
  Future<void> checkAndSaveToken(String uid) async {
    try {
      String? token = await getToken();
      if (token != null) {
        await _firestore.collection('users').doc(uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token saved for user: $uid');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// 當 Token 刷新時自動更新到 Firestore
  Future<void> _onTokenRefresh(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token refreshed and saved for user: ${user.uid}');
      }
    } catch (e) {
      debugPrint('Error updating refreshed FCM token: $e');
    }
  }
}

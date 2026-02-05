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
    // 請求通知權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
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
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  /// 獲取 FCM Token 並儲存到 Firestore
  Future<void> saveTokenToFirestore(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _firestoreService.updateUser(userId, {'fcmToken': token});
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// 設置 Token 刷新監聽器
  void setupTokenRefreshListener() {
    _firebaseMessaging.onTokenRefresh.listen((String token) async {
      debugPrint('FCM Token Refreshed: $token');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await _firestoreService.updateUser(user.uid, {'fcmToken': token});
        } catch (e) {
          debugPrint('Error updating refreshed token: $e');
        }
      }
    });
  }
}

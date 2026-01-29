import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 通知服務 - 負責處理推播通知的權限、Token 管理與發送
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// 初始化通知服務
  Future<void> initialize() async {
    try {
      // 1. 請求權限
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
        return;
      }

      // 2. 獲取 Token
      String? token;
      try {
        token = await _firebaseMessaging.getToken();
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveTokenToDatabase(token);
      }

      // 3. 監聽 Token 刷新
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  /// 將 Token 儲存到 Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {
          'fcmToken': token,
          'lastTokenUpdate': DateTime.now().toIso8601String(),
        });
        debugPrint('Token saved to Firestore');
      } catch (e) {
        debugPrint('Error saving token to Firestore: $e');
      }
    }
  }

  /// 發送配對成功通知
  ///
  /// [targetUserId] 目標用戶 ID
  /// [partnerName] 配對夥伴名稱
  Future<void> sendMatchNotification({
    required String targetUserId,
    required String partnerName,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('sendNotification');
      await callable.call({
        'targetUserId': targetUserId,
        'notificationType': 'match_success',
        'params': {
          'userName': partnerName,
        },
      });
      debugPrint('Match notification sent to $targetUserId');
    } catch (e) {
      debugPrint('Error sending match notification: $e');
      // 不拋出異常，以免中斷主流程
    }
  }
}

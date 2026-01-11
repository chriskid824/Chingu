import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_ab_service.dart';

/// 後台消息處理程序
/// 必須是頂層函數，並且加上 @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 確保 Firebase 初始化
  // 雖然 main.dart 已經初始化，但在後台 isolate 中可能需要重新初始化
  await Firebase.initializeApp();

  debugPrint("Handling a background message: ${message.messageId}");

  // 後台消息通常由系統通知欄處理
  // 這裡可以處理數據消息，例如數據同步或本地存儲更新
}

/// 通知服務 - 處理 FCM Token 管理和消息接收
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

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

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 註冊後台消息處理
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 監聽前台消息
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // 獲取並保存 Token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // 監聽 Token 刷新
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    _isInitialized = true;
  }

  /// 保存 FCM Token 到 Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token updated for user ${user.uid}');
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }
    }
  }

  /// 獲取當前 FCM Token
  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// 刪除 FCM Token
  Future<void> deleteFcmToken() async {
    await _firebaseMessaging.deleteToken();
    User? user = _auth.currentUser;
    if (user != null) {
       try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      } catch (e) {
        debugPrint('Error deleting FCM token from DB: $e');
      }
    }
  }

  /// 處理前台消息
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    String title = message.notification?.title ?? message.data['title'] ?? '';
    String body = message.notification?.body ?? message.data['message'] ?? message.data['body'] ?? '';

    // 如果標題或內容為空，嘗試使用 AB Service 生成內容
    if (title.isEmpty || body.isEmpty) {
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
            final typeStr = message.data['type'];
            NotificationType type;

            // 映射類型字符串到枚舉
            switch (typeStr) {
                case 'match': type = NotificationType.match; break;
                case 'message': type = NotificationType.message; break;
                case 'event': type = NotificationType.event; break;
                case 'rating': type = NotificationType.rating; break;
                default: type = NotificationType.system;
            }

            final content = NotificationABService().getContent(userId, type, params: message.data);
            title = content.title;
            body = content.body;
        }
    }

    // 構建並顯示通知
    if (title.isNotEmpty) {
        final notification = NotificationModel(
          id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: _auth.currentUser?.uid ?? '',
          type: message.data['type'] ?? 'system',
          title: title,
          message: body,
          imageUrl: message.data['imageUrl'],
          actionType: message.data['actionType'],
          actionData: message.data['actionData'],
          createdAt: DateTime.now(),
        );

        RichNotificationService().showNotification(notification);
    }
  }
}

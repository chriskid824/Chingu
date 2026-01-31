import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 請求通知權限
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      // 獲取 FCM Token
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // 監聽 Token 刷新
      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

      // 監聽登入狀態變化，登入後自動更新 Token
      _auth.authStateChanges().listen((User? user) {
        if (user != null) {
          _messaging.getToken().then((token) {
            if (token != null) {
              _saveTokenToFirestore(token);
            }
          });
        }
      });

      // 監聽前台訊息
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        _handleForegroundMessage(message);
      });

      _isInitialized = true;
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  /// 將 Token 儲存到 Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
        debugPrint('FCM Token updated: $token');
      } catch (e) {
        debugPrint('Error updating FCM Token: $e');
      }
    }
  }

  /// 處理前台訊息並顯示豐富通知
  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification == null) return;

    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _auth.currentUser?.uid ?? '',
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? '',
      message: message.notification?.body ?? '',
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );

    // 使用 RichNotificationService 顯示通知
    RichNotificationService().showNotification(notification);
  }
}

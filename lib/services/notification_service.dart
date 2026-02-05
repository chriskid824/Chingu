import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';

// 背景訊息處理器必須是頂層函數
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 這裡可以處理背景訊息
  debugPrint("Handling a background message: ${message.messageId}");
}

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

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. 請求權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    // 2. 註冊背景處理器
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. 處理前台訊息
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      _handleForegroundMessage(message);
    });

    // 4. 處理背景點擊打開 App
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageOpenedApp(message);
    });

    // 5. 處理 Token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // 監聽 Token 更新
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // 6. 監聽登入狀態變化
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _saveTokenToDatabase(token);
        }
      }
    });

    _isInitialized = true;
  }

  /// 處理前台訊息
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      final notificationData = Map<String, dynamic>.from(message.data);

      // 如果 data 中沒有 title 和 message，嘗試從 notification 獲取
      if (!notificationData.containsKey('title') && message.notification?.title != null) {
        notificationData['title'] = message.notification!.title;
      }
      if (!notificationData.containsKey('message') && message.notification?.body != null) {
        notificationData['message'] = message.notification!.body;
      }

      // 確保有必要字段
      if (notificationData['title'] == null || notificationData['message'] == null) {
        return;
      }

      // 補充 NotificationModel 需要的字段
      if (!notificationData.containsKey('userId')) {
        notificationData['userId'] = _auth.currentUser?.uid ?? '';
      }
      if (!notificationData.containsKey('type')) {
        notificationData['type'] = 'system';
      }

      notificationData['createdAt'] = Timestamp.now();

      final notification = NotificationModel.fromMap(
        notificationData,
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      );

      RichNotificationService().showNotification(notification);

    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }

  /// 處理背景點擊
  void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    final String? actionType = data['actionType'];
    final String? actionData = data['actionData'];

    _performNavigation(actionType, actionData);
  }

  void _performNavigation(String? actionType, String? actionData) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    if (actionType == null) {
        navigator.pushNamed(AppRoutes.notifications);
        return;
    }

    switch (actionType) {
      case 'open_chat':
        if (actionData != null) {
          navigator.pushNamed(AppRoutes.chatList);
        } else {
          navigator.pushNamed(AppRoutes.chatList);
        }
        break;
      case 'view_event':
        if (actionData != null) {
          navigator.pushNamed(AppRoutes.eventDetail);
        }
        break;
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList);
        break;
      default:
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }

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
}

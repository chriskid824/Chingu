import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';
import 'firestore_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 這裡可以處理後台消息，通常用於數據同步或顯示本地通知（如果不是通知消息）
  // 由於是隔離的 isolate，不能訪問應用程序狀態
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
  final FirestoreService _firestoreService = FirestoreService();

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

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 設置後台處理器
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 獲取並保存 Token
      try {
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _saveTokenToDatabase(token);
        }

        // 監聽 Token 刷新
        _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

        // 監聽用戶登入狀態變化，確保登入後更新 Token
        _auth.authStateChanges().listen((User? user) {
          if (user != null) {
            _firebaseMessaging.getToken().then((token) {
              if (token != null) {
                _saveTokenToDatabase(token);
              }
            });
          }
        });
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      // 1. 前台消息 (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');

          final notificationModel = _mapRemoteMessageToModel(message);
          RichNotificationService().showNotification(notificationModel);
        }
      });

      // 2. 後台點擊 (Background -> Foreground)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        _handleMessageNavigation(message);
      });

      // 3. 終止狀態點擊 (Terminated -> Foreground)
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App launched from terminated state by notification');
        _handleMessageNavigation(initialMessage);
      }
    }

    _isInitialized = true;
  }

  /// 保存 Token 到 Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestoreService.updateUser(currentUser.uid, {
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token updated for user: ${currentUser.uid}');
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    } else {
      debugPrint('User not logged in, skipping token save');
    }
  }

  /// 處理通知導航
  void _handleMessageNavigation(RemoteMessage message) {
    final String? actionType = message.data['actionType'];
    final String? actionData = message.data['actionData'];

    RichNotificationService().handleNavigation(actionType, actionData, null);
  }

  /// 將 RemoteMessage 轉換為 NotificationModel
  NotificationModel _mapRemoteMessageToModel(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _auth.currentUser?.uid ?? '',
      type: message.data['type'] ?? 'system',
      title: message.notification?.title ?? message.data['title'] ?? '通知',
      message: message.notification?.body ?? message.data['body'] ?? '',
      imageUrl: message.notification?.android?.imageUrl ?? message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );
  }
}

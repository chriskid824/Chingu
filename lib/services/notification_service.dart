import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

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

    // 獲取並更新 Token
    await updateToken();

    // 監聽 Token 刷新
    _firebaseMessaging.onTokenRefresh.listen((token) {
      updateToken(token);
    });

    // 監聽前台訊息
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showForegroundNotification(message);
      }
    });

    // 監聽通知點擊開啟 App
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // TODO: Handle navigation if needed beyond RichNotificationService logic
    });

    _isInitialized = true;
  }

  /// 更新 FCM Token 到 Firestore
  Future<void> updateToken([String? token]) async {
    try {
      String? fcmToken = token ?? await _firebaseMessaging.getToken();

      if (fcmToken == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService().updateUser(user.uid, {
          'fcmToken': fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token updated for user ${user.uid}');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// 顯示前台通知
  void _showForegroundNotification(RemoteMessage message) {
    if (message.notification == null) return;

    final notificationModel = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // 前台顯示不需要 userId
      type: message.data['type'] ?? 'system',
      title: message.notification!.title ?? '',
      message: message.notification!.body ?? '',
      imageUrl: message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl,
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
    );

    RichNotificationService().showNotification(notificationModel);
  }
}

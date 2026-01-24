import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

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

    // 設定背景處理
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 處理前景通知
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // 處理背景開啟 App
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message);
    });

    // 處理終止狀態開啟 App
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage);
    }

    // 獲取並印出 Token (測試用)
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint("FCM Token: $token");
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      final notification = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // 這裡沒有 userId，但在顯示時不需要
        type: message.data['type'] ?? 'system',
        title: message.notification!.title ?? '',
        message: message.notification!.body ?? '',
        imageUrl: message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl,
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
        createdAt: DateTime.now(),
      );

      RichNotificationService().showNotification(notification);
    }
  }

  void _handleNavigation(RemoteMessage message) {
    final String? actionType = message.data['actionType'];
    final String? actionData = message.data['actionData'];
    // Assuming actionId is not relevant for remote notification opening,
    // or we map it from data if exists.

    RichNotificationService().handleNavigation(actionType, actionData, null);
  }
}

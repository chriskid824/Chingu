import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 確保 Firebase 已初始化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Handling a background message: ${message.messageId}');
  // 背景訊息通常由系統托盤處理，但如果是數據訊息，可以在這裡處理
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

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

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 設置背景處理程序
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 處理前台訊息
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
          // 顯示本地通知
          _showForegroundNotification(message);
        }
      });

      // 處理背景應用程式打開
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        _handleNavigation(message);
      });
    }
  }

  /// 設置與通知的交互（應在導航器就緒後調用）
  Future<void> setupInteractedMessage() async {
    // 檢查初始訊息（終止狀態啟動）
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('App launched from terminated state via notification');
      _handleNavigation(initialMessage);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    // 將 RemoteMessage 轉換為 NotificationModel
    // 假設 data 中包含必要的字段
    try {
      final notification = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // 前台顯示不需要 userId
        type: message.data['type'] ?? 'system',
        title: message.notification?.title ?? '新通知',
        message: message.notification?.body ?? '',
        imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl ?? message.data['imageUrl'],
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
        createdAt: DateTime.now(),
      );

      RichNotificationService().showNotification(notification);
    } catch (e) {
      debugPrint('Error showing foreground notification: $e');
    }
  }

  void _handleNavigation(RemoteMessage message) {
    final String? actionType = message.data['actionType'];
    final String? actionData = message.data['actionData'];

    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    if (actionType != null) {
      switch (actionType) {
        case 'open_chat':
          // 導航到聊天列表，因為 ChatDetail 可能需要複雜參數
          navigator.pushNamed(AppRoutes.chatList);
          break;
        case 'view_event':
           navigator.pushNamed(AppRoutes.eventDetail);
           break;
        case 'match_history':
          navigator.pushNamed(AppRoutes.matchesList);
          break;
        default:
          navigator.pushNamed(AppRoutes.notifications);
          break;
      }
    } else {
       // 如果沒有 actionType，默認去通知頁面
       navigator.pushNamed(AppRoutes.notifications);
    }
  }
}

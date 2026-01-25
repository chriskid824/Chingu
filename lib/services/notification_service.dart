import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 請求通知權限
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 處理前景通知
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });

    // 處理背景應用程式開啟（點擊通知）
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // 處理冷啟動（Terminated 狀態點擊通知）
    // 注意：這裡不立即處理，因為 Navigator 可能尚未準備好
    // 而是保存起來，等待 UI 初始化完成後調用 processInitialMessage
    _pendingInitialMessage = await _firebaseMessaging.getInitialMessage();

    _isInitialized = true;
  }

  RemoteMessage? _pendingInitialMessage;

  /// 處理待處理的初始訊息（應在 App 啟動且 Navigator 準備好後調用）
  Future<void> processInitialMessage() async {
    if (_pendingInitialMessage != null) {
      await _handleNotificationTap(_pendingInitialMessage!);
      _pendingInitialMessage = null;
    }
  }

  /// 顯示前景通知
  void _showForegroundNotification(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    if (notification == null && data.isEmpty) return;

    // 映射 FCM type 到 RichNotificationService 的 actionType
    String type = data['type'] ?? 'system';
    String actionType = type;

    // 兼容 RichNotificationService 的 action handling
    if (type == 'chat' || type == 'message') actionType = 'open_chat';
    if (type == 'event') actionType = 'view_event';
    if (type == 'match') actionType = 'match_history';

    final model = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // 前景顯示不需要特定 userId
      type: type,
      title: notification?.title ?? data['title'] ?? '新通知',
      message: notification?.body ?? data['body'] ?? '',
      imageUrl: notification?.android?.imageUrl ?? notification?.apple?.imageUrl ?? data['imageUrl'],
      actionType: actionType,
      actionData: jsonEncode(data),
      createdAt: DateTime.now(),
    );

    RichNotificationService().showNotification(model);
  }

  /// 處理通知點擊導航邏輯
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'];
    final navigator = AppRouter.navigatorKey.currentState;

    if (navigator == null) return;

    debugPrint('Notification Tapped: Type=$type, Data=$data');

    try {
      if (type == 'chat' || type == 'message') {
        final senderId = data['senderId'];
        final chatRoomId = data['chatRoomId'];

        if (senderId != null) {
          // 獲取用戶資料以進入聊天詳情頁
          final user = await _firestoreService.getUser(senderId);
          if (user != null) {
            navigator.pushNamed(
              AppRoutes.chatDetail,
              arguments: {
                'chatRoomId': chatRoomId,
                'otherUser': user,
              },
            );
          } else {
             navigator.pushNamed(AppRoutes.chatList);
          }
        } else {
           navigator.pushNamed(AppRoutes.chatList);
        }
      } else if (type == 'match') {
        // 導航到配對詳情 (User Detail)
        final userId = data['userId'] ?? data['id'];
        navigator.pushNamed(
          AppRoutes.userDetail,
          arguments: userId,
        );
      } else if (type == 'event') {
        // 導航到活動詳情
        final eventId = data['eventId'] ?? data['id'];
        navigator.pushNamed(
          AppRoutes.eventDetail,
          arguments: eventId,
        );
      } else {
        // 預設導航
        navigator.pushNamed(AppRoutes.notifications);
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
      // 出錯時導航回首頁或通知頁
      navigator.pushNamed(AppRoutes.home);
    }
  }
}

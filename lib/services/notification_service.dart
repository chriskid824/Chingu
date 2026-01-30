import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'notification_ab_service.dart';
import 'rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationABService _abService = NotificationABService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 請求通知權限
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

    // 處理前景訊息
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 處理後台點擊
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    _isInitialized = true;
  }

  /// 處理冷啟動訊息 (需在 App 準備好後調用)
  Future<void> processInitialMessage() async {
    // 處理冷啟動
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// 更新 FCM Token
  Future<void> updateFCMToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});

        // 監聽 Token 刷新
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'fcmToken': newToken});
        });
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// 處理前景訊息
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final data = message.data;
      final typeString = data['type'] ?? 'system';

      // 將字串轉換為 NotificationType Enum
      NotificationType type;
      try {
        type = NotificationType.values.firstWhere(
          (e) => e.toString().split('.').last == typeString,
          orElse: () => NotificationType.system,
        );
      } catch (_) {
        type = NotificationType.system;
      }

      // 決定變體和內容
      final experimentGroup = _abService.getGroup(currentUser.uid);
      final variant = experimentGroup == ExperimentGroup.variant ? 'variant' : 'control';

      // 獲取內容 (優先使用後端發送的標題/內容，如果沒有則根據 A/B 測試生成)
      String title = message.notification?.title ?? '';
      String body = message.notification?.body ?? '';

      // 如果是數據訊息 (無 notification 字段)，則使用本地生成的內容
      if (title.isEmpty && body.isEmpty) {
        final content = _abService.getContent(
          currentUser.uid,
          type,
          params: data,
        );
        title = content.title;
        body = content.body;
      }

      // 追蹤發送
      await _abService.trackSend(currentUser.uid, typeString, variant);

      // 構建 NotificationModel
      final notification = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser.uid,
        type: typeString,
        title: title,
        message: body,
        imageUrl: data['imageUrl'],
        actionType: data['actionType'],
        actionData: data['actionData'],
        createdAt: DateTime.now(),
      );

      // 顯示本地通知 (傳遞 variant 以供點擊追蹤)
      await _richNotificationService.showNotification(
        notification,
        variant: variant,
        notificationType: typeString,
      );

    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }

  /// 處理訊息點擊 (後台或終止狀態)
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final data = message.data;
      final typeString = data['type'] ?? 'system';

      // 嘗試獲取 variant (如果在 data 中有攜帶最好，否則重新計算)
      // 注意: 如果這裡是從 terminated 啟動，NotificationService 可能還沒初始化完，
      // 但 currentUser 應該有了。
      final experimentGroup = _abService.getGroup(currentUser.uid);
      final variant = experimentGroup == ExperimentGroup.variant ? 'variant' : 'control';

      // 追蹤點擊
      await _abService.trackClick(currentUser.uid, typeString, variant);

      // 導航邏輯由 RichNotificationService 統一處理
      final payload = {
        'actionType': data['actionType'],
        'actionData': data['actionData'],
        'notificationId': message.messageId,
        'variant': variant,
        'notificationType': typeString,
      };

      _richNotificationService.handleNavigationFromPayload(payload);

    } catch (e) {
      debugPrint('Error handling message open: $e');
    }
  }
}

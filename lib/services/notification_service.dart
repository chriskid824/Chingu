import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'firestore_service.dart';
import 'rich_notification_service.dart';
import 'notification_ab_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationABService _abService = NotificationABService();

  // 記錄已處理的訊息 ID，避免重複處理 (FCM 偶爾會重複發送)
  final Set<String> _processedMessageIds = {};

  Future<void> initialize() async {
    // 請求權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      // 即使沒權限，可能還是需要處理一些邏輯，但暫時返回
      return;
    }

    // 獲取 Token (用於調試或更新後端)
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // 監聽前景訊息
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 監聽後台訊息點擊
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 處理 App 關閉狀態下被點擊啟動的情況
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleMessageOpenedApp(message);
      }
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.messageId != null && _processedMessageIds.contains(message.messageId)) {
      return;
    }
    if (message.messageId != null) {
      _processedMessageIds.add(message.messageId!);
    }

    // 構建 NotificationModel
    final notification = _createNotificationFromRemoteMessage(message);

    if (notification != null) {
        NotificationModel displayNotification = notification;
        String group = 'control';
        final uid = FirebaseAuth.instance.currentUser?.uid;

        if (uid != null) {
             group = _abService.getGroup(uid) == ExperimentGroup.variant ? 'variant' : 'control';

             // 如果標題/內容為空（例如 data-only message），使用 ABService 生成
             if (displayNotification.title.isEmpty && displayNotification.message.isEmpty) {
                 NotificationType typeEnum = _parseNotificationType(displayNotification.type);

                 // 解析參數
                 Map<String, dynamic> params = {};
                 if (message.data.isNotEmpty) {
                    params = Map<String, dynamic>.from(message.data);
                 }

                 final content = _abService.getContent(uid, typeEnum, params: params);

                 displayNotification = NotificationModel(
                    id: displayNotification.id,
                    userId: uid,
                    type: displayNotification.type,
                    title: content.title,
                    message: content.body,
                    imageUrl: displayNotification.imageUrl,
                    actionType: displayNotification.actionType,
                    actionData: displayNotification.actionData,
                    createdAt: displayNotification.createdAt
                 );
             }
        }

        // 追蹤發送
        await trackSend(displayNotification.type, group);

        // 顯示通知，並傳遞 group 以便點擊時追蹤
        await RichNotificationService().showNotification(
          displayNotification,
          extraPayload: {'group': group, 'type': displayNotification.type}
        );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('A new onMessageOpenedApp event was published!');

    final data = message.data;
    final type = data['type'] ?? 'system';

    // 如果是從後台點擊，group 可能無法從本地 AB 測試獲取（因為進程可能剛啟動）
    // 但通常我們可以重新計算 group (deterministic hash)
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String group = 'control';
    if (uid != null) {
      group = _abService.getGroup(uid) == ExperimentGroup.variant ? 'variant' : 'control';
    } else {
      group = data['group'] ?? 'control';
    }

    trackClick(type, group);

    // 導航邏輯通常由 RichNotificationService 或者 Router 處理
    // 這裡我們可以調用 RichNotificationService 的處理邏輯
    // 但因為這是 FCM 直接打開 App，我們可能需要手動觸發導航
    // 這裡暫時只負責追蹤，導航由 AppRouter 監聽或其他機制處理
    // 或者調用 RichNotificationService 的導航輔助方法 (如果在 RichNotificationService 中公開的話)
  }

  /// 追蹤發送
  Future<void> trackSend(String type, String group) async {
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final docId = 'stats_${dateStr}_${group}_${type}';
    await _firestoreService.incrementNotificationStats(docId, isSend: true);
  }

  /// 追蹤點擊
  Future<void> trackClick(String type, String group) async {
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final docId = 'stats_${dateStr}_${group}_${type}';
    await _firestoreService.incrementNotificationStats(docId, isClick: true);
  }

  NotificationModel? _createNotificationFromRemoteMessage(RemoteMessage message) {
      try {
        final data = message.data;
        // 如果 notification 屬性存在，優先使用
        String title = message.notification?.title ?? data['title'] ?? '';
        String body = message.notification?.body ?? data['body'] ?? '';

        return NotificationModel(
          id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: FirebaseAuth.instance.currentUser?.uid ?? '', // 可能為空
          type: data['type'] ?? 'system',
          title: title,
          message: body,
          imageUrl: data['imageUrl'],
          actionType: data['actionType'],
          actionData: data['actionData'],
          createdAt: DateTime.now(),
        );
      } catch (e) {
        debugPrint('Error creating notification model: $e');
        return null;
      }
  }

  NotificationType _parseNotificationType(String type) {
      switch (type) {
        case 'match': return NotificationType.match;
        case 'message': return NotificationType.message;
        case 'event': return NotificationType.event;
        case 'rating': return NotificationType.rating;
        default: return NotificationType.system;
      }
  }
}

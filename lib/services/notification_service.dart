import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../widgets/in_app_notification.dart';
import '../core/routes/app_router.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;

  /// 初始化通知服務
  void initialize() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });
  }

  /// 處理前景訊息
  void _handleForegroundMessage(RemoteMessage message) {
    // 簡單驗證：如果沒有通知內容且沒有數據，則忽略
    if (message.notification == null && message.data.isEmpty) return;

    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) return;

    // 這裡可以加入讀取 AuthProvider 檢查用戶偏好的邏輯
    // 但由於需要 Provider，且 NotificationService 是單例，
    // 目前先直接顯示，後續可優化

    final model = _createModelFromMessage(message);
    if (model == null) return;

    _showInAppNotification(context, model);
  }

  /// 將 RemoteMessage 轉換為 NotificationModel
  NotificationModel? _createModelFromMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'];
    final body = notification?.body ?? data['body'] ?? data['message'];

    if (title == null || body == null) return null;

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // 嘗試從 data 中獲取類型，默認為 system
    final type = data['type'] ?? 'system';

    // 獲取操作數據
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    // 圖片
    final imageUrl = notification?.android?.imageUrl ?? data['imageUrl'];

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      title: title,
      message: body,
      imageUrl: imageUrl,
      actionType: actionType,
      actionData: actionData,
      createdAt: message.sentTime ?? DateTime.now(),
    );
  }

  /// 顯示應用內通知橫幅
  void _showInAppNotification(BuildContext context, NotificationModel model) {
    // 如果已有顯示中的通知，先移除
    _removeNotification();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: InAppNotification(
          notification: model,
          onDismiss: _removeNotification,
          onTap: () {
            _removeNotification();
            _handleNavigation(model);
          },
        ),
      ),
    );

    // 插入 Overlay
    Overlay.of(context).insert(_overlayEntry!);

    // 4秒後自動消失
    _dismissTimer = Timer(const Duration(seconds: 4), _removeNotification);
  }

  /// 移除通知
  void _removeNotification() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 處理導航
  void _handleNavigation(NotificationModel model) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final actionType = model.actionType;
    final actionData = model.actionData;

    switch (actionType) {
      case 'open_chat':
        // 未來可根據 actionData (chatId) 導航至特定聊天室
        navigator.pushNamed(AppRoutes.chatList);
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
        // 默認導航到通知列表
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }
}

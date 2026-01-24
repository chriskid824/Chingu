import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../core/routes/app_router.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';

class RichNotificationService {
  // Singleton pattern
  static final RichNotificationService _instance = RichNotificationService._internal();

  factory RichNotificationService() {
    return _instance;
  }

  RichNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android 初始化設定
    // 預設使用 app icon，需確保 drawable/mipmap 中有 @mipmap/ic_launcher
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化設定
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 請求 Android 13+ 通知權限
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  /// 處理通知點擊事件
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = json.decode(response.payload!);
        final String? actionType = data['actionType'];
        final String? actionData = data['actionData'];
        final String? type = data['type'];

        // 如果是點擊按鈕，actionId 會是按鈕的 ID
        final String? actionId = response.actionId;

        _handleNavigation(actionType, actionData, actionId, type);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// 處理導航邏輯
  void _handleNavigation(String? actionType, String? actionData, String? actionId, String? type) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    // 優先處理按鈕點擊
    if (actionId != null && actionId != 'default') {
      _performAction(actionId, actionData, type, navigator);
      return;
    }

    // 處理一般通知點擊
    if (actionType != null || type != null) {
      _performAction(actionType, actionData, type, navigator);
    }
  }

  Future<void> _performAction(String? action, String? data, String? type, NavigatorState navigator) async {
    // 根據 type 處理導航
    if (type == 'match') {
       navigator.pushNamed(AppRoutes.matchesList);
       return;
    } else if (type == 'event') {
       navigator.pushNamed(AppRoutes.eventDetail);
       return;
    } else if (type == 'message' || action == 'open_chat') {
       await _handleMessageNavigation(data, navigator);
       return;
    }

    // 舊有的 action 處理邏輯 (Fallback)
    if (action == 'view_event') {
      navigator.pushNamed(AppRoutes.eventDetail);
    } else if (action == 'match_history') {
      navigator.pushNamed(AppRoutes.matchesList);
    } else {
      // 預設導航到通知頁面
      navigator.pushNamed(AppRoutes.notifications);
    }
  }

  Future<void> _handleMessageNavigation(String? data, NavigatorState navigator) async {
    if (data == null) {
      navigator.pushNamed(AppRoutes.chatList);
      return;
    }

    String? chatRoomId;
    String? partnerId;

    // 嘗試解析 JSON
    try {
      final jsonData = json.decode(data);
      if (jsonData is Map<String, dynamic>) {
        chatRoomId = jsonData['chatRoomId'];
        partnerId = jsonData['partnerId'] ?? jsonData['userId'];
      }
    } catch (e) {
      // 如果不是 JSON，假設它是 ID (partnerId)
      partnerId = data;
    }

    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) {
       navigator.pushNamed(AppRoutes.chatList);
       return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.uid;

      if (currentUserId == null) {
        navigator.pushNamed(AppRoutes.chatList);
        return;
      }

      UserModel? otherUser;

      // 如果有 partnerId，獲取用戶資料
      if (partnerId != null) {
        otherUser = await FirestoreService().getUser(partnerId);
      }

      // 如果沒有 chatRoomId 但有雙方 ID，查找或創建聊天室
      if (chatRoomId == null && partnerId != null) {
         chatRoomId = await ChatService().createChatRoom(currentUserId, partnerId);
      }

      if (chatRoomId != null && otherUser != null) {
        navigator.pushNamed(
          AppRoutes.chatDetail,
          arguments: {
            'chatRoomId': chatRoomId,
            'otherUser': otherUser,
          },
        );
      } else {
        // 資料不足，退回到列表
        navigator.pushNamed(AppRoutes.chatList);
      }
    } catch (e) {
      debugPrint('Error handling message navigation: $e');
      navigator.pushNamed(AppRoutes.chatList);
    }
  }

  /// 顯示豐富通知
  Future<void> showNotification(NotificationModel notification) async {
    // Android 通知詳情
    StyleInformation? styleInformation;

    // 如果有圖片，下載並設置 BigPictureStyle
    if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty) {
      try {
        final file = await DefaultCacheManager().getSingleFile(notification.imageUrl!);
        final ByteArrayAndroidBitmap bigPicture = ByteArrayAndroidBitmap(await file.readAsBytes());

        styleInformation = BigPictureStyleInformation(
          bigPicture,
          contentTitle: notification.title,
          summaryText: notification.message,
          hideExpandedLargeIcon: true,
        );
      } catch (e) {
        debugPrint('Error downloading image for notification: $e');
        // 圖片下載失敗則降級為普通通知
        styleInformation = BigTextStyleInformation(notification.message);
      }
    } else {
      styleInformation = BigTextStyleInformation(notification.message);
    }

    // 定義操作按鈕
    List<AndroidNotificationAction> actions = [];
    if (notification.actionType == 'open_chat') {
      actions.add(const AndroidNotificationAction(
        'open_chat',
        '回覆',
        showsUserInterface: true,
      ));
    } else if (notification.actionType == 'view_event') {
      actions.add(const AndroidNotificationAction(
        'view_event',
        '查看詳情',
        showsUserInterface: true,
      ));
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'chingu_rich_notifications', // channel Id
      'Rich Notifications', // channel Name
      channelDescription: 'Notifications with images and actions',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: styleInformation,
      actions: actions,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // 構建 Payload
    final Map<String, dynamic> payload = {
      'actionType': notification.actionType,
      'actionData': notification.actionData,
      'notificationId': notification.id,
      'type': notification.type,
    };

    await _flutterLocalNotificationsPlugin.show(
      notification.id.hashCode, // 使用 hashCode 作為 ID
      notification.title,
      notification.message,
      platformChannelSpecifics,
      payload: json.encode(payload),
    );
  }
}

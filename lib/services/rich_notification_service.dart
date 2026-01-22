import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

        // 如果是點擊按鈕，actionId 會是按鈕的 ID
        final String? actionId = response.actionId;

        _handleNavigation(actionType, actionData, actionId);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// 處理導航邏輯
  void _handleNavigation(String? actionType, String? actionData, String? actionId) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    // 優先處理按鈕點擊
    if (actionId != null && actionId != 'default') {
      _performAction(actionId, actionData, navigator);
      return;
    }

    // 處理一般通知點擊
    if (actionType != null) {
      _performAction(actionType, actionData, navigator);
    }
  }

  void _performAction(String action, String? data, NavigatorState navigator) {
    switch (action) {
      case 'open_chat':
        if (data != null) {
          // data 預期是 userId 或 chatRoomId
          // 這裡假設需要構建參數，具體視 ChatDetailScreen 需求
          // 由於 ChatDetailScreen 需要 arguments (UserModel or Map)，這裡可能需要調整
          // 暫時導航到聊天列表
          navigator.pushNamed(AppRoutes.chatList);
        } else {
          navigator.pushNamed(AppRoutes.chatList);
        }
        break;
      case 'view_event':
        if (data != null) {
           // 這裡應該是 eventId，但 EventDetailScreen 目前似乎不接受參數
           // 根據 memory 描述，EventDetailScreen 使用 hardcoded data
           // 但為了兼容性，我們先嘗試導航
          navigator.pushNamed(AppRoutes.eventDetail);
        }
        break;
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList); // 根據 memory 修正路徑
        break;
      default:
        // 預設導航到通知頁面
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }

  /// 顯示豐富通知
  /// [ignoreSettings] 如果為 true，則忽略用戶設定（例如預覽時）
  Future<void> showNotification(NotificationModel notification, {bool ignoreSettings = false}) async {
    // 檢查用戶偏好
    if (!ignoreSettings) {
      final shouldShow = await _checkNotificationPreference(notification);
      if (!shouldShow) {
        debugPrint('Notification suppressed by user settings: ${notification.type}');
        return;
      }
    }

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
    };

    await _flutterLocalNotificationsPlugin.show(
      notification.id.hashCode, // 使用 hashCode 作為 ID
      notification.title,
      notification.message,
      platformChannelSpecifics,
      payload: json.encode(payload),
    );
  }

  /// 檢查用戶偏好設定
  Future<bool> _checkNotificationPreference(NotificationModel notification) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) return true; // 如果找不到用戶，預設顯示

      final data = doc.data();
      if (data == null || !data.containsKey('notificationSettings')) return true;

      final settings = Map<String, dynamic>.from(data['notificationSettings']);

      // 全局開關
      if (settings['push_enable'] == false) return false;

      // 根據類型檢查
      switch (notification.type) {
        case 'match':
          // 這裡簡單映射 match 到 new_match 或 match_success
          // 實際情況可能需要更細分
          return settings['new_match'] == true || settings['match_success'] == true;
        case 'message':
          return settings['new_message'] == true;
        case 'event':
          return settings['dinner_reminder'] == true || settings['dinner_update'] == true;
        case 'rating':
           // 這裡沒有對應的設定，預設顯示或視為系統
           return true;
        case 'system':
          return true; // 系統通知通常不被過濾
        default:
          return true;
      }
    } catch (e) {
      debugPrint('Error checking notification preference: $e');
      return true; // 發生錯誤時預設顯示
    }
  }
}

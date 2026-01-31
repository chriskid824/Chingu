import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';

/// 啟動時的通知資料
class InitialNotificationData {
  final String route;
  final Object? arguments;

  InitialNotificationData({required this.route, this.arguments});
}

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

  /// 檢查是否有初始通知（從通知啟動 App）
  Future<InitialNotificationData?> checkInitialNotification() async {
    // 1. 檢查 FCM 初始訊息 (Terminated state -> Launched)
    try {
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        return _parseNotificationData(
          actionType: initialMessage.data['actionType'],
          actionData: initialMessage.data['actionData'],
        );
      }
    } catch (e) {
      debugPrint('Error checking FCM initial message: $e');
    }

    // 2. 檢查本地通知啟動詳情
    try {
      final NotificationAppLaunchDetails? notificationAppLaunchDetails =
          await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        final payloadResponse = notificationAppLaunchDetails!.notificationResponse;
        if (payloadResponse?.payload != null) {
          final Map<String, dynamic> data = json.decode(payloadResponse!.payload!);
          return _parseNotificationData(
            actionType: data['actionType'],
            actionData: data['actionData'],
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking local notification launch details: $e');
    }

    return null;
  }

  /// 解析通知資料為路由和參數
  InitialNotificationData _parseNotificationData({String? actionType, String? actionData}) {
    switch (actionType) {
      case 'open_chat':
        // 優先導航到聊天列表，因為 ChatDetail 需要完整物件
        // 如果未來支援直接傳 ID，這裡可以改為 chatDetail
        // 這裡也可以考慮使用 arguments: {'initialIndex': 3} 並導航到 mainNavigation
        // 但為了與現有邏輯一致，我們先導航到 chatList
        return InitialNotificationData(route: AppRoutes.chatList);

      case 'view_event':
        // 根據現有邏輯導航到 eventDetail
        return InitialNotificationData(route: AppRoutes.eventDetail);

      case 'match_history':
        return InitialNotificationData(route: AppRoutes.matchesList);

      default:
        return InitialNotificationData(route: AppRoutes.notifications);
    }
  }

  /// 處理通知點擊事件 (Foreground / Background -> Resumed)
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = json.decode(response.payload!);
        final String? actionType = data['actionType'];
        final String? actionData = data['actionData'];
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
    // 重用解析邏輯
    final notificationData = _parseNotificationData(actionType: action, actionData: data);
    navigator.pushNamed(notificationData.route, arguments: notificationData.arguments);
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

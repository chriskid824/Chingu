import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';

class NotificationLaunchDetails {
  final String route;
  final Object? arguments;

  NotificationLaunchDetails(this.route, {this.arguments});
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

  /// 檢查是否是從通知啟動
  Future<NotificationLaunchDetails?> checkInitialLaunch() async {
    // 1. 檢查 Local Notification (Android/iOS)
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload = notificationAppLaunchDetails!.notificationResponse?.payload;
      if (payload != null) {
        try {
          final Map<String, dynamic> data = json.decode(payload);
          return _getLaunchDetailsFromData(
            data['actionType'],
            data['actionData'],
            notificationAppLaunchDetails.notificationResponse?.actionId,
          );
        } catch (e) {
          debugPrint('Error parsing launch payload: $e');
        }
      }
    }

    // 2. 檢查 Firebase Messaging (Remote Notification)
    final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // 解析 FCM 數據
      // 假設 data 結構與 local notification payload 類似，或根據實際情況調整
      final data = initialMessage.data;
      if (data.isNotEmpty) {
        return _getLaunchDetailsFromData(
          data['actionType'],
          data['actionData'],
          null,
        );
      }
    }

    return null;
  }

  NotificationLaunchDetails? _getLaunchDetailsFromData(String? actionType, String? actionData, String? actionId) {
    // 優先處理按鈕點擊
    if (actionId != null && actionId != 'default') {
      return _getActionDetails(actionId, actionData);
    }

    if (actionType != null) {
      return _getActionDetails(actionType, actionData);
    }

    return null;
  }

  NotificationLaunchDetails? _getActionDetails(String action, String? data) {
    switch (action) {
      case 'open_chat':
        if (data != null) {
          // 如果能解析出 chatRoomId，導航到聊天列表或詳情
          // 目前簡單導航到列表，優化時可嘗試解析 data
           return NotificationLaunchDetails(AppRoutes.chatList);
        } else {
          return NotificationLaunchDetails(AppRoutes.chatList);
        }
      case 'view_event':
        // 暫時導航到事件詳情或列表
        return NotificationLaunchDetails(AppRoutes.eventDetail);
      case 'match_history':
        return NotificationLaunchDetails(AppRoutes.matchesList);
      default:
        // 預設導航到通知頁面
        return NotificationLaunchDetails(AppRoutes.notifications);
    }
  }

  /// 處理通知點擊事件 (App 運行中)
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

  /// 處理導航邏輯 (App 運行中)
  void _handleNavigation(String? actionType, String? actionData, String? actionId) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    final details = _getLaunchDetailsFromData(actionType, actionData, actionId);
    if (details != null) {
      navigator.pushNamed(details.route, arguments: details.arguments);
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
